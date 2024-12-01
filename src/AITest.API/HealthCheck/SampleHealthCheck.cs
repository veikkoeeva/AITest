using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace AITest.API.Server.HealthCheck
{
    public class SampleHealthCheckWithDI: IHealthCheck
    {
        //private readonly SampleHealthCheckWithDiConfig _config;

        /*public SampleHealthCheckWithDI(SampleHealthCheckWithDiConfig config)
            => _config = config;*/

        public Task<HealthCheckResult> CheckHealthAsync(
            HealthCheckContext context, CancellationToken cancellationToken = default)
        {
            var isHealthy = true;            
            if(isHealthy)
            {
                return Task.FromResult(
                    HealthCheckResult.Healthy("A healthy result."));
            }

            return Task.FromResult(
                new HealthCheckResult(
                    context.Registration.FailureStatus, "An unhealthy result."));
        }
    }
}
