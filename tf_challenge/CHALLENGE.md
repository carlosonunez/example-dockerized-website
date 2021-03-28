# Challenge Prompt

As we saw in the previous course, Terraform enables you to easily create, change, and
keep track of infrastructure entirely with code. While Terraform supports many providers, our course
focuses on using Terraform to deploy infrastructure into AWS.

In this challenge, you'll be using your new Terraform and Docker skills to
solve a  popular problem in the DevOps space: creating virtual machines in
the AWS Elastic Compute Cloud.

Here's your mission!

- Write a `main.tf` file that creates a VM in AWS EC2 with the `aws_ec2_instance`
  Terraform resource.
- This VM will be named `my-awesome-vm` and it will have the size `t2.micro`.
- It's main disk will be 8GB large.
- Finally, write a Docker Compose service called `terraform` that will
  run Terraform and create this VM.
- The Docker image used for this container should inherit `FROM` Alpine. The
  Dockerfile used to create this image should be saved as `terraform.Dockerfile`.
- Also, make sure that you use container volume mounts to save the
  `.terraform` directory inside of the Terraform container locally onto your machine.

Don't be afraid to use the Docker Compose and Terraform documentation as a guide.

Good luck!

# Solution to the Terraform challenge

Let's dig into the solution for this challenge.

## Creating the Terraform Dockerfile

We'll start by creating our Terraform dockerfile. No hard feelings if you copied
and pasted this from the last part of this course!

First, we'll tell Docker where this image will descend from with our `FROM`
line. Since we're using Alpine as our base, our `FROM` line will look like this:

```dockerfile
FROM alpine
```

Optionally, you can add a maintainer for your image with a `LABEL` annotation:

```dockerfile
LABEL maintainer="Carlos Nunez <dev@carlosnunez.me>"
```

Next, we'll fetch the link to the latest Terraform release available. Remember!
Since we're creating a Linux-based Docker container, we'll need the 64-bit _Linux_
version of Terraform. At the moment, that link is:

```
https://releases.hashicorp.com/terraform/0.14.8/terraform_0.14.8_linux_amd64.zip
```

Next, we'll use `wget` to fetch this image and use `unzip` to extract the
Terraform binary into the root of our container. I like to use the `-O` option
to save this ZIP file into something that's easier to read:

```dockerfile
RUN wget -O terraform.zip https://releases.hashicorp.com/terraform/0.14.8/terraform_0.14.8_linux_amd64.zip
RUN unzip terraform.zip -d /
```

Next, we'll set the entrypoint for our Docker container to use this newly-created
Terraform binary. This way, we can pass the commands that we'll use to
create our infrastructure later into it as if we installed Terraform onto
our computer:

```dockerfile
ENTRYPOINT [ "/terraform" ]
```

Finally, we'll be extra security-conscious and ensure that this container doesn't
run as `root` by adding a `USER` statement and making its default user `nobody`:

```dockerfile
USER "nobody"
```

Now that we have everything we need for our Terraform Dockerfile, let's save this
as `terraform.Dockerfile` and close our editor. We'll quickly
test that it works by building a temporary image from this Dockerfile and using it
to get the version of Terraform that we "installed."

```sh
docker build -t terraform -f terraform.Dockerfile . &&
docker run --rm terraform version
```
