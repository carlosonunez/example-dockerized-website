# Challenge Prompt

As we saw in the previous course, Terraform enables you to easily create, change, and
keep track of infrastructure entirely with code. While Terraform supports many providers, our course
focuses on using Terraform to deploy infrastructure into AWS.

In this challenge, you'll be using your new Terraform and Docker skills to
solve a  popular problem in the DevOps space: creating virtual machines in
the AWS Elastic Compute Cloud.

Here's your mission!

- Write a `main.tf` file that creates a VM in AWS EC2 with the `aws_instance`
  Terraform resource.
- This VM will be named `my-awesome-vm` and it will have the size `t2.micro`.
- Finally, write a Docker Compose service called `terraform` that will
  run Terraform and create this VM.
- The Docker image used for this container should inherit `FROM` Alpine. The
  Dockerfile used to create this image should be saved as `terraform.Dockerfile`.
- Also, use volume mounts to mount your computer's current working directory to a directory
  called `/work` on the Terraform service. Use the `working_dir` statement to make `/work`
  the container's working directory.

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
$: docker build -t terraform -f terraform.Dockerfile .
$: docker run --rm terraform version
Terraform v0.14.8
```

Awesome! Our image works.

## Creating the Terraform Docker Compose service

Next, let's create the `terraform` service in Docker Compose.

All Compose manifests start with a `version` statement. There are several
different versions of the Compose manifest available, each with different features
and abilities. This statement tells Docker Compose which version of that manifest
we want to use.

The latest version available is "3.7". As such, we'll use that here:

```yaml
version: '3.7'
```

Next, we'll create our `terraform` service. Since we're using a custom image,
we'll need to add a `build` statement. Furthermore, since the Dockerfile for
this image is not named `Dockerfile`, we need to use the `dockerfile` parameter
to tell Docker Compose where to find it. We'll also tell Docker Compose
that our context is in our current working directory with the `context`
parameter:

```yaml
services:
  terraform:
    build:
      dockerfile: terraform.Dockerfile
      context: .
```

Next, we want to ensure that the `.terraform` directory that Terraform creates
to save infrastructure state, modules, and other things that Terraform creates
when we run `terraform init`. We can do this with a "volume mount." From looking
at the Docker Compose documentation on this subject, we learn that:

> Mount host paths or named volumes, specified as sub-options to a service.

You can think of volumes created for containers like hard disk images attached
to virtual machines. Since data within Docker containers disappears once the
container is deleted, volumes are used to help you preserve their data so
you can use it later.

From the documentation, we learn that we can mount a local directory on our
machine into the container with the "short" syntax:

> volumes:
>   # rest of docs...
> 
>   # Path on the host, relative to the Compose file
>   - ./cache:/tmp/cache

Let's use this to mount our current directory to the container:

```yaml
services:
  terraform:
    build:
      dockerfile: terraform.Dockerfile
      context: .
    volumes:
      - .:/work
```

However, since Terraform saves its `.terraform` directory into the current
working directory by default and our current working directory is the root
of the container's filesystem (`/`), we should use the `working_dir`
statement to tell Compose that we want to set it to `/work`.

```yaml
services:
  terraform:
    build:
      dockerfile: terraform.Dockerfile
      context: .
    volumes:
      - .:/work
    working_dir: /work
```

That's it! Let's save our file as `docker-compose.yml` and close our editor.

Let's ensure that our service works by using `docker-compose run --rm` to
get the version of Terraform that we're using, just like we did when we tested
our image:

```sh
$: docker-compose run --rm terraform version
Terraform v0.14.8
```

## Creating `main.tf`

Now that we have a working Terraform Docker Compose service, it's time to create Terraform code
for our infrastructure. Let's start by creating a new file called `main.tf`.

Since we're going to use Terraform to create an AWS EC2 instance, we'll need to create an instance
of  the `aws_instance` Terraform resource. Let's write some starter code to make that happen:

```hcl
resource "aws_instance" "vm" {
}
```

Since we haven't used this resource before in our course, let's take a look at the Terraform
documentation to see what we need to provide here.

From looking at the documentation, we need to define only two required parameters:

- `ami`
- `instance_type`

The documentation also shows us how to use a data source to find a machine image ID, or an
`AMI`, that we can use for this machine. Let's use that example verbatim here:

```terraform
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "my_awesome_vm" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = "HelloWorld"
  }
}
```

Finally, since we would like to name this awesome VM `my-awesome-vm`, we'll need to change
the "Name" tag that we've added to this machine to reflect this:

```terraform
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "my_awesome_vm" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = "my-awesome-vm"
  }
}
```

Lookin' good! 😎 Let's save this file and close our editor.

## Setting up AWS access

Before we can run this Terraform code, we need to change our Docker Compose a little
bit. As you'll recall from our previous chapter, we'll need to define a few
environment variables to connect Terraform to AWS. These environment variables
are:

`AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY`, and
`AWS_REGION`.

We'll need to create a new IAM account in AWS to get an `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
that we can use here. Let's dig into the AWS console now and get this done.

First, I'll log in with my email and password.

Next, I'll type "IAM" in the search box up top and click on the first result to open the IAM console.

Next, I'll click on "Users" then on "Add User" to create a new user.

I'll need to give this user a user name. Let's call it "terraform-user". We'll also need to
click on "Programmatic Access" so that we can get the access key and secret key we'll need to run
Terraform.

Next, I'll click on "Next: Permissions" to give this user super-user rights. This is easy:
I'll click on "Attach existing policies directly", then on "Administrator Access".

Next, I'll check on "Next: Tags". We won't be adding any tags for this user, so I'll click on
"Next: Review" to skip straight to the review screen.

Everything in the "Review" page looks good, so I'll click on "Create User" to create
our `terraform-user`. Exciting!

Once this is done, I'm taken to a Success page. This is where we get our access key and secret
access key. Take a look at this section here. This is really important. This is where we'll
see our Secret Key. **THIS IS THE ONLY TIME AWS WILL EVER SHOW YOU THIS.** If you forget it or lose
it, you'll need to create a new access key and secret access key!

This seems like a great time to put these keys into our Docker Compose file, right? Let's do that
now. Don't close your browser, though! We'll need it later.

Let's open `docker-compose.yml` and add an environment section under `working_dir` for our
environment variables:

```yaml
environment:
  AWS_ACCESS_KEY_ID: access-key
  AWS_SECRET_ACCESS_KEY: secret-key
  AWS_REGION: us-east-2
```

A quick note about `AWS_REGION`. I'm using the `us-east-2` region since it's the region that's
closest to me in Texas where I'm recording this. You should choose a different region that's closer
to where you are to avoid slowness. You can see a list of AWS regions from the link shown
below. (**INSTRUCTOR NOTE**: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html)

Cool! Let's save this file and exit our editor.

## Viewing the Terraform Plan

We're _finally_ ready to check out our Terraform plan. First, let's
run `docker-compose run --rm terraform init` to initialize Terraform:

```sh
$: docker-compose run --rm terraform init
```

Let's make sure that Terraform created a `.terraform` folder in our working directory.
This will confirm that the volume mount we created earlier works.

```sh
$: ls -a .
.  ..  .terraform  .terraform.lock.hcl  CHALLENGE.md  docker-compose.yml  main.tf  terraform.Dockerfile
```

Cool! It's there. Game on.

Now that we've initialized Terraform, let's see what our Terraform plan looks like:

```sh
$: docker-compose run --rm terraform plan
An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_instance.web will be created
  + resource "aws_instance" "vm" {
      + ami                          = "ami-02fc6052104add5ae"
      + arn                          = (known after apply)
      + associate_public_ip_address  = (known after apply)
      + availability_zone            = (known after apply)
      + cpu_core_count               = (known after apply)
      + cpu_threads_per_core         = (known after apply)
      + get_password_data            = false
      + host_id                      = (known after apply)
      + id                           = (known after apply)
      + instance_state               = (known after apply)
      + instance_type                = "t2.micro"
      + ipv6_address_count           = (known after apply)
      + ipv6_addresses               = (known after apply)
...
```

Excellent! We get a plan. Let's check a few things before we apply it.

- Let's look at the `ami` value. It's a really long string. This means
  that our data source successfully found a machine image for Ubuntu 20.04
  per our search parameters.
- Our instance size is indeed `t2.micro`.
- We have a `my-awesome-vm` "Name" tag, as expected.

It's always good to look at a Terraform plan before you deploy to make sure
that you don't deploy something wrong and potentially expensive!

## Applying the Terraform VM

Now that we've confirmed that our plan looks good, let's create this awesome
VM!

```sh
$: docker-compose run --rm terraform apply
```

We'll be asked if we want to apply this plan. Since we do, we'll type "yes."
Once we do that, Terraform will work its magic!

```sh
aws_instance.vm: Creating...
aws_instance.vm: Still creating... [10s elapsed]
aws_instance.vm: Still creating... [20s elapsed]
aws_instance.vm: Creation complete after 23s [id=i-02f563d7a783e6747]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

Our VM has now been created! Let's go back into the AWS console and confirm
that it's there.

Click on the text box in the blue AWS bar. Type "EC2," then click on the
first result to go to the EC2 console. Next, click on the drop-dwon next to
your name and confirm that it matches the region that you set `AWS_REGION` to.
Mine was set to "N. Virginia (us-east-1)." Since I deployed my machine into
us-east-2, I'll need to select "Ohio (us-east-2)."

Next, click on "Instances (running)." It should say "1" to the right of it.

You should see a VM called "my-awesome-vm" in this part of the console. If
you do, then congratulations, you've deployed you first VM with Terraform inside
of Docker!

## Cleaning up

Since we aren't going to do anything with this machine, let's delete what we've
just created with the `terraform destroy` command. Go back to your terminal
and run this:

```sh
$: docker-compose run --rm terraform destroy
```

Just like `terraform plan`, you'll be asked if you want to do this. Type "yes"
to confirm. Once you do, Terraform will delete your VM:

```
aws_instance.vm: Destroying... [id=i-02f563d7a783e6747]
aws_instance.vm: Still destroying... [id=i-02f563d7a783e6747, 10s elapsed]
aws_instance.vm: Still destroying... [id=i-02f563d7a783e6747, 20s elapsed]
aws_instance.vm: Still destroying... [id=i-02f563d7a783e6747, 30s elapsed]
aws_instance.vm: Destruction complete after 31s

Destroy complete! Resources: 1 destroyed.
```

Notice that the Terminal shows you the ID of the VM that we're destroying. This is
accomplished through the state file that Terraform creates. Terraform's state file
keeps track of this and much, much more. This is what makes Terraform so attractive
for managing infrastructure of all sizes over more manual options like Chef, Ansible,
Puppet, or scripts.

Finally, let's go back to the EC2 console and refresh the page. You should
see that the VM has been deleted.

Now that we've confirmed that, we can go back to our Terminal and delete
the `.terraform` directory.

Congratulations on completing our challenge!
