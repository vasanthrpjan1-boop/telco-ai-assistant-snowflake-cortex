-- Configure Attendee Account

-- Create the Attendee role if it does not exist
use role SECURITYADMIN;
create role if not exists {{ env.EVENT_ATTENDEE_ROLE }};

-- Ensure account admin can see what {{ env.EVENT_ATTENDEE_ROLE }} can see
grant role {{ env.EVENT_ATTENDEE_ROLE }} to role ACCOUNTADMIN;

-- Grant the necessary priviliges to that role.
use role ACCOUNTADMIN;
grant CREATE DATABASE on account to role {{ env.EVENT_ATTENDEE_ROLE }};
grant CREATE ROLE on account to role {{ env.EVENT_ATTENDEE_ROLE }};
grant CREATE WAREHOUSE on account to role {{ env.EVENT_ATTENDEE_ROLE }};
grant MANAGE GRANTS on account to role {{ env.EVENT_ATTENDEE_ROLE }};
grant CREATE INTEGRATION on account to role {{ env.EVENT_ATTENDEE_ROLE }};
grant CREATE APPLICATION PACKAGE on account to role {{ env.EVENT_ATTENDEE_ROLE }};
grant CREATE APPLICATION on account to role {{ env.EVENT_ATTENDEE_ROLE }};
grant IMPORT SHARE on account to role {{ env.EVENT_ATTENDEE_ROLE }};


-- Create the warehouse
create or replace warehouse {{ env.EVENT_WAREHOUSE }}
    AUTO_SUSPEND = 60;

-- Create the users
use role USERADMIN;
create or replace user {{ env.EVENT_USER_NAME }}
    PASSWORD = '{{ env.EVENT_USER_PASSWORD }}'
    LOGIN_NAME = {{ env.EVENT_USER_NAME }}
    FIRST_NAME = '{{ env.EVENT_USER_FIRST_NAME }}'
    LAST_NAME = '{{ env.EVENT_USER_LAST_NAME }}'
    MUST_CHANGE_PASSWORD = false
    TYPE = PERSON;
create or replace user {{ env.EVENT_ADMIN_NAME }}
    PASSWORD = '{{ env.EVENT_ADMIN_PASSWORD }}'
    LOGIN_NAME = {{ env.EVENT_ADMIN_NAME }}
    FIRST_NAME = '{{ env.EVENT_ADMIN_FIRST_NAME }}'
    LAST_NAME = '{{ env.EVENT_ADMIN_LAST_NAME }}'
    MUST_CHANGE_PASSWORD = false
    TYPE = PERSON;

-- Ensure the user can use the role and warehouse
use role SECURITYADMIN;
grant role {{ env.EVENT_ATTENDEE_ROLE }} to user {{ env.EVENT_USER_NAME }};
grant USAGE on warehouse {{ env.EVENT_WAREHOUSE }} to role {{ env.EVENT_ATTENDEE_ROLE }};

-- Ensure ADMIN can use ACCOUNTADMIN role
grant role ACCOUNTADMIN to user {{ env.EVENT_ADMIN_NAME }};

-- Alter the users to set default role and warehouse
use role USERADMIN;
alter user {{ env.EVENT_USER_NAME }} set
    DEFAULT_ROLE = {{ env.EVENT_ATTENDEE_ROLE }}
    DEFAULT_WAREHOUSE = {{ env.EVENT_WAREHOUSE }};
alter user {{ env.EVENT_ADMIN_NAME }} set
    DEFAULT_ROLE = ACCOUNTADMIN
    DEFAULT_WAREHOUSE = {{ env.EVENT_WAREHOUSE }};

-- Create the database and schemas using {{ env.EVENT_ATTENDEE_ROLE }}
use role {{ env.EVENT_ATTENDEE_ROLE }};

create or replace database {{ env.DATAOPS_DATABASE }};
create or replace schema {{ env.DATAOPS_DATABASE }}.{{ env.EVENT_SCHEMA }};

-- If data sharing enambled, create a database from the share
{% if env.EVENT_DATA_SHARING == "true" %}
use role {{ env.EVENT_ATTENDEE_ROLE }};
create database if not exists {{ env.EVENT_SHARE }} from share {{ env.DATAOPS_SHARE_ACCOUNT | replace('-', '.') | upper }}.{{ env.EVENT_SHARE }};
grant imported privileges on database {{ env.EVENT_SHARE }} to role PUBLIC;
{% endif %}