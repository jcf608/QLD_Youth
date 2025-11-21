# Queensland Youth Justice - Use Case Analysis

## Overview

This repository contains research, use case analysis, and documentation related to the Queensland Department of Youth Justice case management system (Unify) and potential opportunities for enhancement through the UTS/OPTIk Program.

## Background

The Queensland Department of Youth Justice uses **Unify**, an integrated digital case management system custom-built by the state government. Unify began development in 2019 to streamline child safety and youth justice operations, replacing the older Integrated Client Management System (ICMS).

## Project Scope

This project explores potential pro bono opportunities to enhance operational efficiency and service delivery across multiple personas in the youth justice ecosystem:

- **Case Managers** - Managing youth aged 10-17 in the justice system
- **Victim Support Coordinators** - Providing crisis intervention and court navigation
- **Program Managers** - Overseeing rehabilitation and intervention programs
- **Frontline Officers** - Community corrections and field supervision
- **Strategic Planners** - Executive-level policy development and reporting

## Use Cases

Detailed use case scenarios are documented in:
- [ScenariosForQLDYouth.md](./ScenariosForQLDYouth.md) - Persona definitions and pain points

## Key Challenges Identified

- Data fragmentation across multiple legacy systems
- Manual reconciliation and reporting processes
- Limited field access to case information
- Inconsistent inter-agency information sharing
- Program effectiveness measurement gaps

## Resources

- [Queensland Audit Office Report](https://qao.qld.gov.au/reports-resources/reports-parliament/implementing-new-child-safety-and-youth-justice-case-management-system)
- [iTnews Coverage](https://itnews.com.au/story/qld-child-safety-taps-deloitte-to-assess-core-it-system)

## Project Team

Kyndryl Strategic Sales & Solutioning Team

## Application

This repository contains a full-stack web application built with:
- **Backend:** Sinatra + Ruby + ActiveRecord + PostgreSQL
- **Frontend:** React + Vite + TailwindCSS + Lucide React

### Quick Start

For complete setup instructions, see [README_SETUP.md](./README_SETUP.md)

```bash
# Install dependencies
bundle install
cd client && npm install && cd ..

# Setup database
createdb qld_youth_development
bundle exec rake db:migrate db:seed

# Start both servers (ports 3090-3091)
./start
```

Visit: `http://localhost:3091`

**Alternative:** Use `./start-dev.sh` for default ports (9292, 3000)

## License

This is internal project documentation for pro bono initiative planning.

---

*Last Updated: November 2025*

