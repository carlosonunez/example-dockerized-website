# What's the goal here?

The goal is to show users how to build an application with a Docker image
and run it in a container.

# What do people need to know beforehand?

- How Docker works, specifically:
  - What containers are, and the problems they are meant to solve
  - How they differ from virtual machines (a common confusion)
  - What container images are, and how they are structured (i.e the Union File System)

# Demo Steps

## Building your first image

1. Create a new `Dockerfile`: `touch Dockerfile`
2. Open it in an editor, like Visual Studio Code or Atom
3. Write the `Dockerfile` provided in the `answers` directory (which contains
   more explanations of each step)
   1. Remember to mention the Docker Reference Guide for more information
      on the `Dockerfile` language.
   2. Remember to mention that this is where additional configuration for your
      application should live. Explain how simple, idempotent and easily-readable configuration
      is a main advantage of using Docker over traditional configuration
      management systems for application packaging.
4. Build it, and give it a name: `docker build -t my_awesome_website .`
  1. Remember to briefly show the `docker-build` man page to show users
    that more options exist here.
  2. Walk through these steps:
     - `Sending context` (where it sends the current directory to the Docker engine
       so that it can build your image using intermediate containers and
       container images, or layers)
     - `Pulling from library/ruby` (Where it attempts to find the image your image
       descends from in Docker Hub)
       - Note that this can be changed if your organization has an internal
         repository available.
     - `Fetching gem metadata` (where it's fetching dependencies for your app)
     - `Successfully built` (where it indicates that the final image has been
       created and is ready for use)
     - `Successfully tagged` (where it appended the name that you gave the image
       onto it so that the Engine can find it when you `run` a container from it)
5. Run it: `docker run --publish 8080:8080 my_awesome_website`
  - Note that Docker doesn't discard the container by default when you create it.
6. Open a browser and navigate to `http://localhost:8080`.
   You should see "My Awesome Website" appear.

## Making changes

7. Stop the container (CTRL-C)
7. Make a change to `views/index.markdown` file; anything will do.
8. Rebuild the Docker image again.
  - Remember to note how it has to fetch all of your dependencies again
    because the change to the file above changed the `COPY` layer, which changes
    all layers below it.
9. Run the container again: `docker run --rm --publish 8080:8080 my_awesome_website`

## Optimizing build speed (optional)

10. Stop the container: `docker kill my_awesome_website`
11. Modify the `Dockerfile` to look like `Dockerfile.optimized`.
12. Build the image.
13. Run the container and show the functional website.
14. Stop the container.
15. Make a change to `views/index.markdown` again.
16. Build the image. Be sure to note the increase in speed here!
17. Stop the container.

# Additional Information

- The Dockerfile Reference: https://docs.docker.com/engine/reference/builder/
