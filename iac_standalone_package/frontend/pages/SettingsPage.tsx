import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Layout } from '../components/layout/Layout';
import { Card } from '../components/common/Card';
import { Button } from '../components/common/Button';
import { CloudDeploymentService } from '../services/cloudDeployment';
import { GitHubService } from '../services/github';

export function SettingsPage() {
  const navigate = useNavigate();
  const [selectedProvider, setSelectedProvider] = useState<'azure' | 'aws' | 'gcp'>('azure');
  const [deploying, setDeploying] = useState(false);
  const [deploymentResult, setDeploymentResult] = useState<any>(null);
  const [deploymentProgress, setDeploymentProgress] = useState<string[]>([]);
  const [error, setError] = useState('');
  const [testing, setTesting] = useState(false);
  const [testResult, setTestResult] = useState<any>(null);
  const [resourceGroups, setResourceGroups] = useState<any[]>([]);
  const [loadingResources, setLoadingResources] = useState(false);
  const [destroying, setDestroying] = useState(false);
  const [destroyProgress, setDestroyProgress] = useState('');
  const [showDeploySection, setShowDeploySection] = useState(false);
  
  // GitHub timestamp upload state
  const [githubToken, setGithubToken] = useState('');
  const [uploadingTimestamp, setUploadingTimestamp] = useState(false);
  const [uploadResult, setUploadResult] = useState<any>(null);
  const [uploadError, setUploadError] = useState('');

  // Auto-load resources on mount
  useEffect(() => {
    loadResources();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const loadResources = async () => {
    try {
      setLoadingResources(true);
      setError('');
      const result = await CloudDeploymentService.getResources(selectedProvider);
      setResourceGroups(result.resource_groups || []);
      console.log('Loaded resource groups:', result.resource_groups);
    } catch (err: any) {
      console.error('Failed to load resources:', err);
      // Don't show error on initial load - might not be authenticated yet
      // setError(err.message || 'Failed to load resources');
    } finally {
      setLoadingResources(false);
    }
  };

  const handleTestConnection = async () => {
    try {
      setTesting(true);
      setError('');
      setTestResult(null);
      
      const result = await CloudDeploymentService.testConnection(selectedProvider);
      setTestResult(result);
      
      // Load resources after successful connection test
      if (result.success) {
        await loadResources();
      }
    } catch (err: any) {
      setError(err.message || 'Connection test failed');
    } finally {
      setTesting(false);
    }
  };

  const handleDeploy = async () => {
    if (!confirm(`Deploy infrastructure to ${selectedProvider.toUpperCase()}? This will create cloud resources and may incur costs.`)) {
      return;
    }

    try {
      setDeploying(true);
      setError('');
      setDeploymentResult(null);
      setDeploymentProgress([]);
      
      // Deploy with real-time progress updates
      const result = await CloudDeploymentService.deploy(
        selectedProvider, 
        {},
        (message) => {
          // Add new progress message only if it's different from the last one
          setDeploymentProgress(prev => {
            if (prev.length === 0 || prev[prev.length - 1] !== message) {
              return [...prev, message];
            }
            return prev;
          });
        }
      );
      
      setDeploymentResult(result);
      
      // Reload resources after successful deployment
      await loadResources();
    } catch (err: any) {
      console.error('Deployment error:', err);
      
      // Extract error message
      let errorMsg = 'Deployment failed';
      if (typeof err === 'string') {
        errorMsg = err;
      } else if (err.message && typeof err.message === 'string') {
        errorMsg = err.message;
      } else if (err.error && typeof err.error === 'string') {
        errorMsg = err.error;
      }
      
      setError(errorMsg);
    } finally {
      setDeploying(false);
    }
  };

  const handleDestroy = async (resourceGroupName: string, resourceCount: number) => {
    if (!confirm(`⚠️ DESTROY ALL RESOURCES in ${resourceGroupName}?\n\nThis will permanently delete:\n- ${resourceCount} resources\n- The entire resource group\n\nThis action CANNOT be undone!`)) {
      return;
    }

    try {
      setDestroying(true);
      setError('');
      setDestroyProgress('Initiating deletion...');
      
      await CloudDeploymentService.destroy(selectedProvider, resourceGroupName);
      
      // Azure deletion is async, poll until resource group is actually gone
      // Poll for up to 5 minutes (60 attempts x 5 seconds)
      setDestroyProgress('Deletion initiated. Waiting for Azure to complete deletion...');
      
      let attempts = 0;
      const maxAttempts = 60;
      let resourceGroupGone = false;
      
      while (attempts < maxAttempts && !resourceGroupGone) {
        await new Promise(resolve => setTimeout(resolve, 5000)); // Wait 5 seconds
        attempts++;
        
        const elapsed = attempts * 5;
        setDestroyProgress(`Waiting for deletion to complete... (${elapsed}s elapsed)`);
        
        try {
          const result = await CloudDeploymentService.getResources(selectedProvider);
          const stillExists = result.resource_groups?.some((rg: any) => rg.name === resourceGroupName);
          
          if (!stillExists) {
            resourceGroupGone = true;
            break;
          }
        } catch (err) {
          // If we can't check, assume it's gone
          resourceGroupGone = true;
          break;
        }
      }
      
      // Final reload to update UI
      setDestroyProgress('Refreshing resource list...');
      await loadResources();
      setDestroyProgress('');
      
      if (resourceGroupGone) {
        alert(`✅ Resource group "${resourceGroupName}" destroyed successfully!\n\n📦 Database Cleanup:\nThe system has:\n- Backed up your document provenance data\n- Removed orphaned RAG infrastructure (chunks, embeddings, indexes)\n- Preserved all user data, settings, and credentials\n- Maintained referential integrity\n\nAll documents remain in the system with status reset to 'pending' for reprocessing.`);
      } else {
        alert(`⚠️ Deletion initiated for "${resourceGroupName}". Resources are still being deleted in the background. Please refresh the page in a few minutes to verify.`);
      }
    } catch (err: any) {
      console.error('Destroy error:', err);
      setError(err.message || 'Failed to destroy resources');
    } finally {
      setDestroying(false);
      setDestroyProgress('');
    }
  };

  const handleUploadTimestamp = async () => {
    if (!githubToken.trim()) {
      setUploadError('Please enter a GitHub Personal Access Token');
      return;
    }

    try {
      setUploadingTimestamp(true);
      setUploadError('');
      setUploadResult(null);

      const result = await GitHubService.uploadTimestamp(
        'https://github.com/JamesCurrieFreeman/test_repo.git',
        githubToken
      );

      if (result.success && result.data) {
        setUploadResult(result.data);
        setUploadError('');
      } else {
        setUploadError(result.error?.message || 'Upload failed');
      }
    } catch (err: any) {
      console.error('Upload error:', err);
      setUploadError(err.message || err.error?.message || 'Failed to upload timestamp');
    } finally {
      setUploadingTimestamp(false);
    }
  };

  return (
    <Layout>
      <div className="space-y-6">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-3xl font-bold text-text">Settings</h1>
            <p className="text-text-secondary mt-2">
              Configure system settings and cloud infrastructure
            </p>
          </div>
          
          <Button
            variant="secondary"
            size="small"
            onClick={() => window.open('/subway.html', '_blank')}
          >
            📊 View Platform Map
          </Button>
        </div>

        {/* Cloud Infrastructure Deployment */}
        <Card title="Cloud Infrastructure" padding="large">
          <div className="space-y-4">
            {/* Provider Selection and Actions */}
            <div className="flex items-center justify-between bg-surface p-3 rounded">
              <div className="flex items-center gap-3">
                <label className="text-sm text-text-secondary">Provider:</label>
                <select
                  value={selectedProvider}
                  onChange={(e) => setSelectedProvider(e.target.value as 'azure' | 'aws' | 'gcp')}
                  className="px-3 py-1.5 text-sm border border-border rounded bg-white text-text focus:ring-2 focus:ring-primary"
                  aria-label="Cloud provider selection"
                >
                  <option value="azure">Azure</option>
                  <option value="aws">AWS (Soon)</option>
                  <option value="gcp">GCP (Soon)</option>
                </select>
              </div>
              
              <div className="flex items-center gap-2">
                <Button
                  variant="secondary"
                  onClick={handleTestConnection}
                  loading={testing}
                  disabled={deploying || selectedProvider !== 'azure'}
                  size="small"
                >
                  Test Connection
                </Button>
                
                <button
                  onClick={() => setShowDeploySection(!showDeploySection)}
                  className="text-sm text-info hover:underline px-2"
                >
                  {showDeploySection ? 'Hide Deploy' : 'Deploy New'}
                </button>
              </div>
            </div>

            {/* Resources Display - Main Content */}
            <div>
              <h3 className="text-sm font-semibold text-text mb-3">Allocated Resources</h3>
              
              {/* Destroy Progress Indicator */}
              {destroying && destroyProgress && (
                <div className="flex items-center gap-2 text-sm text-warning p-3 bg-warning/10 rounded mb-3 border border-warning/30">
                  <div className="w-4 h-4 border-2 border-warning border-t-transparent rounded-full animate-spin" />
                  {destroyProgress}
                </div>
              )}
              
              {loadingResources ? (
                <div className="flex items-center gap-2 text-sm text-text-secondary p-3 bg-surface rounded">
                  <div className="w-4 h-4 border-2 border-primary border-t-transparent rounded-full animate-spin" />
                  Loading resources...
                </div>
              ) : resourceGroups.length > 0 ? (
                <div className="space-y-3">
                  {resourceGroups.map((rg: any, rgIdx: number) => (
                    <div key={rgIdx} className="border-2 border-border rounded-lg p-4 bg-white">
                      <div className="flex items-center justify-between mb-3 pb-3 border-b">
                        <div>
                          <div className="text-base font-semibold text-text">
                            {rg.name}
                          </div>
                          <div className="text-xs text-text-secondary mt-1">
                            {rg.resource_count} resources in {rg.location}
                          </div>
                        </div>
                        <Button
                          variant="danger"
                          onClick={() => handleDestroy(rg.name, rg.resource_count)}
                          loading={destroying}
                          disabled={deploying || testing}
                          size="small"
                        >
                          🗑️ Destroy
                        </Button>
                      </div>
                      <div className="space-y-2">
                        {rg.resources.map((resource: any, idx: number) => (
                          <div key={idx} className="flex items-center justify-between py-1 px-2 hover:bg-surface/50 rounded">
                            <span className="text-sm text-text">• {resource.name}</span>
                            <span className="text-xs text-text-secondary">{resource.type?.split('/').pop()}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-sm text-text-secondary p-4 bg-surface/50 rounded border-2 border-dashed border-border">
                  No resources deployed yet. Click "Deploy New" to create infrastructure.
                </div>
              )}
            </div>

            {/* Expandable Deploy Section */}
            {showDeploySection && (
              <div className="bg-white border-2 border-info rounded-lg p-4 space-y-3">
                <h4 className="text-sm font-semibold text-text">Deploy New Infrastructure</h4>
                <div className="text-sm text-text-secondary">
                  Creates: Storage Account, Form Recognizer, AI Search (eastasia region)
                </div>
                <Button
                  variant="primary"
                  onClick={handleDeploy}
                  loading={deploying}
                  disabled={testing || selectedProvider !== 'azure'}
                  size="small"
                >
                  Deploy to {selectedProvider.toUpperCase()}
                </Button>
              </div>
            )}

            {/* Test Result */}
            {testResult && (
              <div className={`p-2 rounded text-xs ${testResult.success ? 'bg-white text-success border-2 border-success' : 'bg-white text-error border-2 border-error'}`}>
                {testResult.success ? (
                  <span>✅ Connected: {testResult.account_name}</span>
                ) : (
                  <span>❌ {testResult.error}</span>
                )}
              </div>
            )}

            {/* Deployment Progress */}
            {deploying && deploymentProgress.length > 0 && (
              <div className="bg-info/10 rounded p-4">
                <div className="text-xs text-info font-medium mb-3 flex items-center gap-2">
                  <div className="w-3 h-3 border-2 border-info border-t-transparent rounded-full animate-spin" />
                  Deploying infrastructure...
                </div>
                <div className="space-y-2">
                  {deploymentProgress.map((step, idx) => (
                    <div key={idx} className="flex items-start gap-2 text-xs">
                      <span className="text-success mt-0.5">
                        {idx === deploymentProgress.length - 1 && deploying ? '⏳' : '✅'}
                      </span>
                      <span className={idx === deploymentProgress.length - 1 ? 'text-text font-medium' : 'text-text-secondary'}>
                        {step}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Deployment Success */}
            {deploymentResult && (
              <div className="bg-white text-success text-xs p-2 rounded border-2 border-success">
                ✅ Deployed successfully
              </div>
            )}

            {/* Error Display */}
            {error && (
              <div className="bg-white text-error text-xs p-2 rounded border-2 border-error">
                ❌ {error}
              </div>
            )}
          </div>
        </Card>

        {/* Job Monitoring */}
        <Card title="Job Monitoring" padding="large">
          <div className="space-y-4">
            <p className="text-text-secondary">
              Monitor Redis and Sidekiq background job processing, view queue statistics, and track worker performance.
            </p>
            <Button
              variant="primary"
              onClick={() => navigate('/jobs')}
            >
              📊 View Job Monitor
            </Button>
          </div>
        </Card>

        {/* GitHub Timestamp Upload */}
        <Card title="GitHub Integration Test" padding="large">
          <div className="space-y-4">
            <p className="text-text-secondary text-sm">
              Upload a timestamp file to test GitHub repository integration.
              This will create or update <code className="px-1 py-0.5 bg-surface rounded text-xs font-mono">timestamp.txt</code> in the repository root.
            </p>

            <div className="space-y-3">
              <div>
                <label className="block text-sm font-medium text-text mb-2">
                  GitHub Personal Access Token
                </label>
                <input
                  type="password"
                  value={githubToken}
                  onChange={(e) => setGithubToken(e.target.value)}
                  placeholder="ghp_xxxxxxxxxxxxxxxxxxxx"
                  className="w-full px-3 py-2 border border-border rounded-medium text-sm focus:ring-2 focus:ring-primary focus:border-primary"
                />
                <p className="text-xs text-text-secondary mt-1">
                  Token needs <code className="px-1 py-0.5 bg-surface rounded font-mono">repo</code> permission
                </p>
              </div>

              <div className="flex items-center gap-3">
                <Button
                  variant="primary"
                  onClick={handleUploadTimestamp}
                  loading={uploadingTimestamp}
                  disabled={!githubToken.trim()}
                  size="small"
                >
                  📤 Upload Timestamp to test_repo
                </Button>
                
                {uploadResult && (
                  <a
                    href={uploadResult.file_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-sm text-primary hover:underline"
                  >
                    View File →
                  </a>
                )}
              </div>
            </div>

            {/* Upload Result */}
            {uploadResult && (
              <div className="bg-white text-success text-sm p-3 rounded border-2 border-success">
                <div className="font-semibold mb-1">✅ Upload Successful!</div>
                <div className="text-xs space-y-1">
                  <div>Timestamp: {uploadResult.timestamp}</div>
                  <div>
                    <a href={uploadResult.file_url} target="_blank" rel="noopener noreferrer" className="underline">
                      View file on GitHub
                    </a>
                  </div>
                  <div>
                    <a href={uploadResult.commit_url} target="_blank" rel="noopener noreferrer" className="underline">
                      View commit
                    </a>
                  </div>
                </div>
              </div>
            )}

            {/* Upload Error */}
            {uploadError && (
              <div className="bg-white text-error text-sm p-3 rounded border-2 border-error">
                ❌ {uploadError}
              </div>
            )}
          </div>
        </Card>

        {/* Environment Variables */}
        <Card title="Azure Configuration" padding="large">
          <div className="space-y-4">
            <p className="text-text-secondary text-sm">
              Configure these environment variables for Azure deployment:
            </p>
            <div className="font-mono text-sm bg-surface p-4 rounded-medium border border-border">
              <div>AZURE_SUBSCRIPTION_ID=your-subscription-id</div>
              <div>AZURE_TENANT_ID=your-tenant-id</div>
              <div className="mt-2 text-text-secondary"># Optional - will be auto-generated if not provided:</div>
              <div>AZURE_RESOURCE_GROUP=uts-dev-rg</div>
              <div>AZURE_LOCATION=eastus</div>
              <div className="mt-2 text-text-secondary"># Optional - filter which resource groups to display:</div>
              <div>AZURE_RESOURCE_GROUP_PREFIX=uts</div>
              <div className="text-text-secondary"># (If not set, shows ALL resource groups)</div>
            </div>
          </div>
        </Card>
      </div>
    </Layout>
  );
}

export default SettingsPage;

