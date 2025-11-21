#!/bin/bash

echo "🚀 Starting QLD Youth Justice Case Management System"
echo "=================================================="

# Check if PostgreSQL is running
if ! pg_isready > /dev/null 2>&1; then
    echo "❌ PostgreSQL is not running. Please start PostgreSQL first."
    exit 1
fi

echo "✅ PostgreSQL is running"

# Check if database exists
if ! psql -lqt | cut -d \| -f 1 | grep -qw qld_youth_development; then
    echo "📦 Creating database..."
    createdb qld_youth_development
    bundle exec rake db:migrate
    bundle exec rake db:seed
else
    echo "✅ Database exists"
fi

echo ""
echo "Starting servers..."
echo "Backend: http://localhost:9292"
echo "Frontend: http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop all servers"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping servers..."
    kill 0
}

trap cleanup EXIT

# Start backend server
cd "$(dirname "$0")"
bundle exec rackup -p 9292 &

# Start frontend server
cd client
npm run dev &

# Wait for all background processes
wait

