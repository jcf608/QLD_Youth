import apiClient from './api';

export interface DeploymentResult {
  success: boolean;
  provider: string;
  resources?: Array<{
    type: string;
    name: string;
    endpoint?: string;
  }>;
  message?: string;
  error?: string;
}

export interface ConnectionTestResult {
  success: boolean;
  provider?: string;
  account_name?: string;
  subscription_id?: string;
  error?: string;
}

export class CloudDeploymentService {
  static async deploy(provider: string, config: any = {}, onProgress?: (message: string) => void): Promise<DeploymentResult> {
    // Start async deployment
    const response = await apiClient.post<any>(
      '/cloud/deploy',
      { provider, config }
    );
    
    if (!response.success || !response.data?.deployment_id) {
      throw new Error(response.error?.message || 'Failed to start deployment');
    }

    const deploymentId = response.data.deployment_id;
    
    // Poll for status updates
    return await this.pollDeploymentStatus(deploymentId, onProgress);
  }

  private static async pollDeploymentStatus(
    deploymentId: string,
    onProgress?: (message: string) => void
  ): Promise<DeploymentResult> {
    while (true) {
      await new Promise(resolve => setTimeout(resolve, 2000)); // Poll every 2 seconds
      
      const statusResponse = await apiClient.get<any>(`/cloud/deploy/${deploymentId}/status`);
      
      if (!statusResponse.success || !statusResponse.data) {
        throw new Error('Failed to get deployment status');
      }

      const status = statusResponse.data;
      
      // Update progress callback
      if (onProgress && status.message) {
        onProgress(status.message);
      }

      // Check if deployment is complete
      if (status.status === 'completed') {
        return {
          success: true,
          provider: 'azure',
          resources: status.data,
          message: status.message
        };
      }

      if (status.status === 'failed') {
        throw new Error(status.message || 'Deployment failed');
      }

      // Continue polling for other statuses
    }
  }

  static async testConnection(provider: string): Promise<ConnectionTestResult> {
    const response = await apiClient.post<ConnectionTestResult>(
      '/cloud/test',
      { provider }
    );
    
    if (response.success && response.data) {
      return response.data;
    }
    
    throw new Error(response.error?.message || 'Connection test failed');
  }

  static async getStatus(): Promise<any> {
    const response = await apiClient.get<any>('/cloud/status');
    
    if (response.success && response.data) {
      return response.data;
    }
    
    throw new Error(response.error?.message || 'Failed to get cloud status');
  }

  static async getResources(provider: string): Promise<{ resource_groups: any[] }> {
    const response = await apiClient.get<any>(`/cloud/resources?provider=${provider}`);
    
    if (response.success && response.data) {
      return response.data;
    }
    
    throw new Error(response.error?.message || 'Failed to get resources');
  }

  static async destroy(provider: string, resourceGroup: string): Promise<void> {
    const response = await apiClient.post<any>(`/cloud/destroy`, {
      provider,
      resource_group: resourceGroup
    });
    
    if (!response.success) {
      throw new Error(response.error?.message || 'Failed to destroy resources');
    }
  }
}

export default CloudDeploymentService;

