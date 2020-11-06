1) Set up a highly-available WordPress service on AWS. Task breakdown:

- Create VPC with private and public subnets. Use at least 2 AZs
- Create a Multi-AZ RDS database for WordPress. Enable backups for the last 3 days.
- Create EFS to store web server files.
- Create a multi-AZ auto-scaling group for WordPress instances. Mount EFS as /var/www/. Make sure all instances share the same EFS and have a connection to the RDS database.
- Create ALB in front of WordPress instances. Make it terminate the SSL traffic. Use ACM to generate free certificates for wordpress.support-coe.com.
- Create DNS record wordpress.support-coe.com pointing to your load balancer.
- Make sure security groups are configured properly. DB should be accessed only from app instances.
Use minimal instances size (t2.micro)  to save cost.
IEC and CM tools like Terraform/CloudFormation/Ansible are an advantage.

2) Create an ELK stack running on EC2.

- Create network infrastructure (VPC, subnets, NATs, IGW, etc). Use at least 2 AZs.
- Create and configure EC2 infrastructure that consists of:
  a. 3-node Elasticsearch cluster. Spin up EC2 instances and install elastic search. Configure them to run as a cluster. Place in the private subnet.
  b. 2 nodes of logstash log forwarder. Use Elasticsearch nodes as output. Place in a private OR public subnet. Be ready to describe a use case for the chosen option.
  c. 1 node kibana+nginx. Configure OAuth with GitHub provider to authenticate users. They should be able to access kibana with their GitHub account. Place in a public subnet.
  d. 1 node webserver or another log generator. Use the filebeat as a log shipper. Configure it to send logs to logstash nodes.
    HINT. If you did the HA Wordpress task you can get logs from wordpress instances. Than you don't need to spin up separate server.
- Create a local DNS hosted zone for elastic search and logstash nodes.
- Create public DNS for kibana under elk.support-coe.com
Use minimal instances size to save cost. Elasticsearch may require more than t2.micro to run.
IEC and CM tools like Terraform/CloudFormation/Ansible are an advantage

3) Create a lambda function that checks the health of some secured HTTP endpoints. Task breakdown:

- Create VPC with private and public subnets
- Create a lambda function that:
  a. Makes HTTP calls to some endpoint (current - lambda.support-coe.com) and tracks HTTP response code every 5 minutes.
  b. Based on the response code it should make a decision if the endpoint is healthy or not. [2xx, 3xx] - healthy, [4xx, 5xx] - unhealthy.
  c. Sends notification to your mentor's mail if there are 3 failed checks in a row.
    HINT. You can do it with bare lambda, but it could be easier with the involvement of other AWS services.
  d. Make function execute inside of your private subnet.
  e. Make adding new endpoints easy to do.
IaC tools like Terraform and CloudFormation will be an advantage

![Imgur](https://i.imgur.com/YmYQ4eX.png)
![Imgur](https://i.imgur.com/KIhMM1g.png)
![Imgur](https://i.imgur.com/SdMyhSl.png)
