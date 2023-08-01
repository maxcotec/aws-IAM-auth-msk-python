# Access IAM-Auth MSK cluster with Python

AWS MSK (Managed access for streaming apache kafka) comes with 3 authentication methods. One of which is IAM auth. 
Which means that in-order to access kafka cluster, you need to be assigned an AWS IAM user or IAM role with necessary permissions. 
This authentication method is proprietary to AWS services, hences in-order to successfully pass the auth layer, 
AWS provides its own JAR file, that sits on top of kafka cluster, which does the necessary check, before granting necessary access. 
This jar files works well in only two scenarios, a) It can perfectly integrate with you JAVA app, or 
b) if you are using kafka cli consumer or producer. 
But what if your application is written in python? The existing python kafka packages does not have any support for 
get pass this AWS IAM auth layer.  

This is a sneaky way of getting around to this problem by using python subprocess to access kafka-console tools to access 
kafka cluster. 

Watch Videos tutorials:

Part 1: [AWS msk kafka tutorial | Access IAM authentication](https://youtu.be/r12HYxWAJLo) 

Part 2: IAM auth enabled auth kafka acces via Python (Coming soon) 

## IAM permissions
before running this code, make sure you have correct IAM permissions assigned. 
### Read-only policy
read-only policy on topic `test-topic`, group `reader-group` and any transactional-id;
```json
{
    "Statement": [
        {
            "Action": [
                "kafka-cluster:ReadData",
                "kafka-cluster:DescribeTransactionalId",
                "kafka-cluster:DescribeTopicDynamicConfiguration",
                "kafka-cluster:DescribeTopic",
                "kafka-cluster:DescribeGroup",
                "kafka-cluster:DescribeClusterDynamicConfiguration",
                "kafka-cluster:DescribeCluster",
                "kafka-cluster:Connect",
                "kafka-cluster:AlterGroup"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:kafka:eu-west-1:12345678:transactional-id/demo-kafka-cluster/*/*",
                "arn:aws:kafka:eu-west-1:12345678:topic/demo-kafka-cluster/*/test-topic",
                "arn:aws:kafka:eu-west-1:12345678:group/demo-kafka-cluster/*/reader-group*",
                "arn:aws:kafka:eu-west-1:12345678:cluster/demo-kafka-cluster/*"
            ]
        }
    ],
    "Version": "2012-10-17"
}
```

### Read-write (Admin) policy

```json
{
    "Statement": [
        {
            "Action": "kafka-cluster:*",
            "Effect": "Allow",
            "Resource": [
                "arn:aws:kafka:eu-west-1:12345678:transactional-id/demo-kafka-cluster/*/*",
                "arn:aws:kafka:eu-west-1:12345678:topic/demo-kafka-cluster/*/*",
                "arn:aws:kafka:eu-west-1:12345678:group/demo-kafka-cluster/*/*",
                "arn:aws:kafka:eu-west-1:12345678:cluster/demo-kafka-cluster/*"
            ]
        }
    ],
    "Version": "2012-10-17"
}
```

Be sure to change account-id and region accordingly.

#### Terraform

Terraform code is also available `terraform/` if any of you fancy deploying these policies, roles and users via IaC. Just fill in the
values in `terraform/terraform.auto.tfvars`.

## Prepare machine
Where ever you will be running this code (EC2 or K8s etc), you need to make sure the machine has following three requirements;
1. java
2. kafka
3. [AWS-IAM jar](https://github.com/aws/aws-msk-iam-auth)

Follow below commands to install and configure all above;
```js
apt-get update
apt-get -y upgrade

apt-get -y install nano vim tar wget default-jre

wget https://downloads.apache.org/kafka/3.4.1/kafka_2.12-3.4.1.tgz
tar -xzvf kafka_2.12-3.4.1.tgz
rm -rf kafka_2.12-3.4.1.tgz

wget https://github.com/aws/aws-msk-iam-auth/releases/download/v1.1.6/aws-msk-iam-auth-1.1.6-all.jar
mv aws-msk-iam-auth-1.1.6-all.jar kafka_2.12-3.4.1/libs

printf 'security.protocol=SASL_SSL  \n\
sasl.mechanism=AWS_MSK_IAM              \n\
sasl.jaas.config=software.amazon.msk.auth.iam.IAMLoginModule required;    \n\
sasl.client.callback.handler.class=software.amazon.msk.auth.iam.IAMClientCallbackHandler \
' >> kafka_2.12-3.4.1/client.properties
```

A Dockerfile (`Dockerfile_base`) is also available in you want to wrap this inside a docker image. 

## Run Instructions

Before running the code, make sure to export IAM user credentials. The python script needs read-write access.
```js
export AWS_ACCESS_KEY_ID=<>
export AWS_SECRET_ACCESS_KEY=<>
```

To run the python app that listens on topic `test-topic2` and sends on `test-topic`;

```js
python main.py --sub-topic test-topic2 --kafka-servers <bootstrap-servers> --pub-topic test-topic --configs kafka_2.12-3.4.1/client.properties
```

### cli Instructions

Create topic;
```js
./kafka_2.12-3.4.1/bin/kafka-topics.sh --bootstrap-server <bootstrap-servers> --replication-factor 2 --partition 1 --topic <topic-name> --command-config ./kafka_2.12-3.4.1/client.properties
```

Producer (export read-write iam user credentials):
```js
./kafka_2.12-3.4.1/bin/kafka-console-producer.sh --bootstrap-server <bootstrap-servers> --topic test-topic2 --producer.config kafka_2.12-3.4.1/client.properties
```

Consumer (export read-only iam user credentials):
```js
./kafka_2.12-3.4.1/bin/kafka-console-consumer.sh --bootstrap-server <bootstrap-servers> --topic test-topic --consumer.config kafka_2.12-3.4.1/client.properties --group reader-group
```
