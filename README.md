# Overview

This project contains the default configuration to automate the setup of an attendee account for an event.

The automated setup is done using jobs located at [pipelines/includes/local_includes/](pipelines/includes/local_includes/).

## Configuration

After forking this project, you can change the configure DATAOPS_PREFIX to make the forked project more unique to your event:

1. Update [pipelines/includes/config/variables.yml](pipelines/includes/config/variables.yml#L11) file with a new value for DATAOPS_PREFIX.

DATAOPS_PREFIX is used to create unique names for the resources created by the project, for example the name of database created during attendee account configuration.

### Pipeline overview table

| Job                        | Stage                    | Description                                                   |
|----------------------------|--------------------------|---------------------------------------------------------------|
| Initialise Pipeline        | Pipeline Initialisation  | This job sets up the pipeline.                                |
| Build Homepage             | Pipeline Initialisation  | This job builds the event instructions specific for attendee. |
| Share Data To Attendee     | Data Sharing             | (Optional) This job shares data with the attendee account.    |
| Configure Attendee Account | Attendee Account Setup   | This job configures the attendee account.                     |

### SQL scripts

The following SQL scripts are used to setup an attendee account. Written as Jinja templates, the scripts make use of the variables available when the pipeline runs.

| Script                          | Location                                                                                                       | Description                                                       |
|---------------------------------|----------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| share_data_to_attendee.sql      | [dataops/event/share_data_to_attendee.template.sql](dataops/event/share_data_to_attendee.template.sql)         | This script makes a data share available to the attendee account. |
| configure_attendee_account.sql  | [dataops/event/configure_attendee_account.template.sql](dataops/event/configure_attendee_account.template.sql) | This script configures the attendee account.                      |

### Event Configuration Variables set in the project

These variables are set in this project, with default values to be changed in the [pipelines/includes/config/variables.yml](pipelines/includes/config/variables.yml) file.

| Variable Name                 | Description                                                     |
|-------------------------------|-----------------------------------------------------------------|
| EVENT_WAREHOUSE               | The warehouse created in the attendee account.                  |
| EVENT_SCHEMA                  | The schema created in the attendee account.                     |
| EVENT_ATTENDEE_ROLE           | The role created in the attendee account for the attendee user. |
| EVENT_USER_NAME               | The user name for the attendee user.                            |
| EVENT_USER_FIRST_NAME         | The first name for the attendee user.                           |
| EVENT_USER_LAST_NAME          | The last name for the attendee user.                            |
| EVENT_USER_PASSWORD           | The password for the attendee user.                             |
| EVENT_ADMIN_NAME              | The user name for the admin user.                               |
| EVENT_ADMIN_FIRST_NAME        | The first name for the admin user.                              |
| EVENT_ADMIN_LAST_NAME         | The last name for the admin user.                               |
| EVENT_ADMIN_PASSWORD          | The password for the admin user.                                |
| EVENT_DATA_SHARING            | The flag to enable data sharing with the attendee account.      |
| EVENT_SHARE                   | The share to be shared with the attendee account.               |

### Event Configuration Variables from Event Management App

These variables are set by the Event Management App and are passed to a pipeline when it is triggered.

| Variable Name                 | Description                                               |
|-------------------------------|-----------------------------------------------------------|
| EVENT_NAME                    | The name of the event.                                    |
| EVENT_SLUG                    | The slug of the event.                                    |
| EVENT_START_DATETIME          | The start date and time of the event.                     |
| EVENT_END_DATETIME            | The end date and time of the event.                       |
| EVENT_DECOMMISSION_DATETIME   | The decommission date and time of the event.              |
| EVENT_CHILD_ACCOUNT_NAME      | The name of the attendee account.                         |
| EVENT_CHILD_ACCOUNT_SLUG      | The slug of the attendee account.                         |
| EVENT_ORG_NAME                | The org name where the attendee accounts are provisioned. |

### Data Sharing

If data sharing is enabled, by setting the EVENT_DATA_SHARING variable to "true", the following variables are required to access the account with the share.

These variables can be set in the variables.yml file, or in the projects CI/CD settings.

| Variable Name                 | Description                                                              |
|-------------------------------|--------------------------------------------------------------------------|
| DATAOPS_SHARE_ACCOUNT         | The account identifier of the account with the share.                    |
| DATAOPS_SHARE_USER            | The user for accessing the account with the share.                       |
| DATAOPS_SHARE_PRIVATE_KEY     | The private key for accessing the account with the share.                |
| DATAOPS_SHARE_ROLE            | The role for accessing the account with the share.                       |

## Attendee Account Outputs

The following file defines the outputs of the attendee account setup. These variables are used to pass information to the attendee through the Event Management App.

[dataops/event/attendee_account_outputs.template.env](dataops/event/attendee_account_outputs.template.env)

At the end of the Configure Attendee Account job, this .env file gets created as a job artifact. The Event Management App reads this file to get the content.

## Hints and tips

### Run homepage in Develop

To run the homepage in a develop workspace, run the following commands:

```bash
$(pyenv which pip) install -U -r requirements.txt
mkdocs serve
```
