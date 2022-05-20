# Using the Docker image

Using packages that are dependent of rJava can be tricky. Alternatively you may not want to use R or some other reason.
If so the docker approach may be best.
After you have [installed docker](https://www.docker.com/get-started/) and downloaded the datasets do the following...

- navigate to the dockerfile folder in the repo
- the command `docker build . -t foi_docker/latest:latest`
- Go back to the main repo folder
- Run the command docker `run --rm -it -v $(pwd):/app foi_docker/latest:latest`
- laugh as all java issues plaugue someone else.

# Notes

the docker command `-v $(pwd):/app` maps the present working directory on your command line to the `app` directory within the docker container.
This makes all the files and folders in this folder available to the docker container. As a result it is important that you run the docker container
from the base folder of the repo i.e. `..../lsoa_foi_form_maker`. If you run the container from somewhere else you will need to replace `$(pwd)` with 
the full path name. 

This repo is set up to run on UNIX like systems aka Linux and Apple, if you are using windows the `/` in the above instructions will need to be replaced with `\`.