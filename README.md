# app-template

`app-template` is the template repository for integrating new apps into the HIP. It can be used as a template when creating a new repository for an app.

## :warning: Important :warning:

Please do not hardcode the `app` version number. The version number will be provided to you via the variable `${APP_VERSION}`, so you can use it within the commands to install the `app`. This is necessary to be able to provide seemless updates to users, and properly tag the docker image that will be generated using your `Dockerfile`.

## `Dockerfile` modifications

The provided `Dockerfile` must be completed and modified for the new app that you wish to integrate. All parts of the `Dockerfile` marked with `<>` must be completed:

1. `<base-image:version>`: the following base images are available (all base images are based on Ubuntu 20.04 LTS):
    - `${DOCKERFS_TYPE}:${DOCKERFS_VERSION}`: if you don't need matlab-runtime, the FS type and version will be provided by the `${DOCKERFS_TYPE}` and `${DOCKERFS_VERSION}` variables
    - `matlab-runtime:R2020a_u7`: if you need matlab-runtime version 2020a update 7
    - `matlab-runtime:R2020b_u6`: if you need matlab-runtime version 2020b update 6
    - `jupyterlab-desktop:${JUPYTERLAB_DESKTOP_VERSION}`: if you need to run jupyterlab-desktop, the Jupyterlab Desktop version will be provided by the `${JUPYTERLAB_DESKTOP_VERSION}` variable
 
    You have to use one of these base images, this is mandatory for your app to be integrated into the HIP.

2. `<maintainer@example.com>`: replace by your email address.

2. `<app>`: ubuntu package of the app to be installed. If such a package does not exist, please execute the necessary commands to install it as part of this `RUN` command. Make sure to purge all unnecessary packages at the end to keep the docker image as compact as possible. Do not forget to make use of the `${APP_VERSION}` variable.

3. `<option>`: the following options are available:
    - `no`: when it's a regular app
    - `terminal`: when the app must be ran from a terminal.
    - `jupyterlab-desktop`: when the app must be ran from jupyterlab-desktop. In this case, use the `jupyterlab-desktop` base image in step 1.

    If used, leave `</path/to/app/executable>` in step 4 and `<app_process_name>` in step 5 empty, otherwise set to `no`.

4. `</path/to/app/executable>`: absolute path to the app executable.

5. `<app_process_name>`: the exact name of the app process (if several use the parent process). You can find out by installing the app on Ubuntu 20.04 and running the command `ps faux`. This information is important for the health check as well as synchronizing files to Nextcloud after the `app` exited.

6. `<app_config_dir .app_config_dir>`: list of directories necessary for the app to function and retain its state (database, preferences, etc.). These directories will be synced to Nextcloud and mounted into the container. The specified paths must be relative to the user home directory. For now files aren't supported, but support can be added if needed.

7. `<app_data_dir1 app_data_dir2>`: list of data directories necessary to be able to run the app. These directories will be synced to Nextcloud and mounted into the container. The specified paths must be relative to the user home directory. For now files aren't supported, but support can be added if needed.

## Acknowledgement

This project has received funding from the  European Union's Horizon Europe research and innovation program under grant agreement No 101147319 and from the Swiss State Secretariat for Education, Research and Innovation (SERI) under contract number 23.00638, as part of the Horizon Europe project “EBRAINS 2.0”.

This research was supported by the EBRAINS research infrastructure, funded from the European Union’s Horizon 2020 Framework Programme for Research and Innovation under the Specific Grant Agreement No. 945539 (Human Brain Project SGA3).
