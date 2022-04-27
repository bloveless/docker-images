# ecr-credential-helper
A docker image to help populate ecr credentials into service account secrets. This will loop through all the namespaces
in the NAMESPACES environment variable and will get/set a new docker registry secret for ECR. The secret will expire in
12 hours so it would be useful to add this to a cronjob that runs less than 12 hours apart. See the example below.

**This image has been moved to bloveless/docker-images**

## Environment variables
All environment variables are required.

`AWS_ACCOUNT_ID`: AWS Account Id

`AWS_SECRET_ACCESS_KEY`: AWS Secret Access Key

`AWS_ACCESS_KEY_ID`: AWS Access Key ID

`AWS_DEFAULT_REGION`: AWS Region

`EMAIL`: This doesn't really matter but the kubernetes docker registry command requires it. Just set it to your email.

`NAMESPACES`: The namespaces to set the ecr pull credentials for. These are space separated.

## Example kubernetes usage

```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  annotations:
  name: ecr-cred-helper-cronjob
  namespace: utils
spec:
  suspend: false
  schedule: "0 */8 * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          terminationGracePeriodSeconds: 30
          containers:
            - name: ecr-cred-helper
              image: bloveless/ecr-credential-helper:ADD_YOUR_TAG_HERE
              imagePullPolicy: IfNotPresent
              env:
                - name: AWS_ACCOUNT_ID
                  value: "3xxxxxxxxxx6"
                - name: AWS_DEFAULT_REGION
                  value: us-west-2
                - name: AWS_SECRET_ACCESS_KEY
                  valueFrom:
                    secretKeyRef:
                      name: aws-access-keys-secret
                      key: secretAccessKey
                - name: AWS_ACCESS_KEY_ID
                  valueFrom:
                    secretKeyRef:
                      name: aws-access-keys-secret
                      key: accessKeyId
                - name: EMAIL
                  value: my-cool-email@gmail.com
                - name: NAMESPACES
                  value: "default,namespace-1,namespace-2"
```
