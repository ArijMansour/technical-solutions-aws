## Question 1 – What weaknesses can you see in the current architecture?

1. **Internal apis are publicly exposed**
   - Apis meant for internal use are accessible from the internet, which unnecessarily increases the security risk

2. **Direct internet access to internal apis**
   - Internal apis can be reached via the internet or through CloudFront, which broadens the attack surface

3. **Lack of advanced traffic routing**
   - The current setup doesn't seem to take advantage of path-based routing in CloudFront, making it harder to manage traffic depending on the audience (internal, external, partners)

4. **Waf can be bypassed**
   - Since regional API Gateway endpoints are directly accessible, it's possible for attackers to circumvent the CloudFront and WAF protections

5. **Decentralized api management**
   - Apis are built by different teams but exposed through separate endpoints. This fragmentation can lead to inconsistent security and governance practices

6. **No clear boundary between internal and external traffic**
   - The architecture doesn't properly separate internal from external traffic, which complicates both monitoring and securing the system

7. **Weak defense in depth**
   - Even though WAF and AWS Shield are in place, the ability to bypass them through direct API Gateway access reveals a gap in layered security

## Question 2 – How would you redesign the architecture to make internal APIs private while maintaining external access?

1. **Use private api gateway endpoints**
   - Set up VPC Endpoints for API Gateway within the internal network
   - Configure internal apis to be reachable only through those private endpoints
   - Remove any public access for internal-only apis

2. **Separate api gateways for internal and external traffic**
   - Internal Gateway: Accessible only from inside the corporate network
   - External Gateway: Remains public, but strictly serves apis intended for outside users

3. **Strengthen network access controls**
   - Apply resource policies to restrict access to specific VPC Endpoints
   - Use security groups to tightly control traffic flow
   - Set up internal DNS resolution using Route 53 for clean routing to private apis

4. **Adjust backend connectivity**
   - Place Lambda functions and internal ALBs in a VPC for secure private communication
   - Use cross-account IAM roles if services span multiple AWS accounts
   - Consider PrivateLink for secure, private cross-service communication

## Question 3 – How could CloudFront be configured to route traffic based on path-based routing?

1. **Set up cache behaviors with specific path patterns**
   - Define path rules like:
     - `/internal/*` → Routes to Internal API Gateway
     - `/external/*` → Routes to External API Gateway
     - `/partner/*` → Routes to Partner API Gateway

2. **Add multiple origins**
   - Each API Gateway gets its own origin:
     - `internal-api.execute-api.<region>.amazonaws.com`
     - `external-api.execute-api.<region>.amazonaws.com`
     - `partner-api.execute-api.<region>.amazonaws.com`

3. **Tune behavior settings per path**
   - Enable or disable caching based on use case
   - Enforce HTTPS and limit allowed HTTP methods
   - Attach different WAF rules per behavior for tailored security

## Question 4 – How would you protect regional API Gateway endpoints from direct access bypassing CloudFront/WAF?

1. **Enforce api gateway resource policies**
   - Allow requests only from specific CloudFront distributions or IPs
   - Deny all other sources by default

2. **Use custom headers from cloudfront**
   - Inject a secret header into all requests coming through CloudFront
   - Validate this header in API Gateway using a Lambda authorizer
   - Rotate the secret periodically for added security

3. **Require api keys and usage plans**
   - Force API key usage for all Gateway requests
   - Use usage plans to control rate limits and monitor behavior
   - Inject API keys at the CloudFront level if needed

4. **Attach waf directly to the api gateway**
   - Complement CloudFront-level WAF with another layer directly on API Gateway
   - Use it to perform rate limiting, inspect IP reputation, or block malicious patterns