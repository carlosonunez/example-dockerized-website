FROM ruby:alpine
MAINTAINER Carlos Nunez <dev@carlosnunez.me>

# First, we'll copy the source code for our application into our Docker image.
# This will allow containers created from this image to run the app.
COPY . /app

# Next, we'll set our current directory to the folder we just created.
# This makes it easier for us to start the app because we won't need
# to find where it is.
WORKDIR /app

# Next, we'll install the application's dependencies. This way, any containers
# started from this image can start immediately knowing that its environment
# is configured and ready to go.
RUN bundle install

# Finally, we'll set the default command for containers invoked from this image.
# This makes it easy for our users to consume the app, as they will not need
# to know how the application starts in order to use it. 

# We can do this one of two ways: with an ENTRYPOINT, or with a CMD. There is a lot of
# confusion and mistakes made between the two, so a long explanation is warranted here.

# ## ENTRYPOINTs

# An ENTRYPOINT sets the default executable that will run when the container
# is invoked from this image. This makes the container an "application" of sorts.
# There are two methods of creating an ENTRYPOINT: using the _exec_ form, or
# using the _shell_ form.

# The _exec_ form (shown below) is an array of strings describing the actions
# for the container to take upon invocation. This form also allows users to specify
# additional arguments to the application either through the `docker run`
# command or through CMD (explained below). Most importantly, the _exec_ form
# sets the application as PID 1 for the container. This allows it to capture
# signals from the host like SIGINT (CTRL+C) or SIGQUIT (Ctrl+\), which can
# be handy when dealing with hung containers.

# The _shell_ form is easier to write since it can be written as a string. It
# looks like this:
#
# ENTRYPOINT ruby website.rb

# However, writing it this way tells Docker to start your application using
# `sh -c`. This will make `sh` PID 1 for your container, which means that your
# application _might_ not capture signals during runtime (i.e. if your
# container hangs, you'll need to kill it with `docker kill`). It also
# prevents users from passing arguments into it, since they will be passing
# arguments into `sh` instead of your application.

# The _exec_ form is the preferred way of defining an ENTRYPOINT.

# ## CMDs

# CMDs are used to set defaults for the application optionally specified by
# the ENTRYPOINT command. If an ENTRYPOINT is not specified, the container will
# run `sh -c` by default.

# There are three ways of specifying CMDs:
#
# - _exec_ form (Launch an executable, optionally with parameters; _preferred_)
# - _param_ form (Specify parameters to provide to the default application), and
# - _shell_ form (Run a command under a shell)

# Like `ENTRYPOINT`, the _exec_ and _param_ forms are JSON arrays, while the
# _shell_ form is a string.

# Note that any parameters specified by CMD will be overriden by whatever
# is provided through `docker run`.
ENTRYPOINT [ "ruby", "website.rb" ]
CMD [ "website.rb" ]

# Next, we will expose the port that we expect the application to be running
# on. This is more for documentation, as you will need to _publish_ it when
# you run the container.
EXPOSE 8080

# Finally, we will set our default user to something other than `root`
# (the default). This secures your container by preventing it from accessing
# files that it shouldn't have access to and secures your hosts from
# container-based privilege escalation attacks.
USER nobody
