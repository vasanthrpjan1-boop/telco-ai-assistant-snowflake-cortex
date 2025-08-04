-- Configure Attendee Account
ALTER SESSION SET QUERY_TAG = '''{"origin":"sf_sit-is", "name":"Build an AI Assistant for FSI using Cortex and Document AI", "version":{"major":1, "minor":0},"attributes":{"is_quickstart":0, "source":"sql"}}''';
-- Create the warehouse
USE ROLE ACCOUNTADMIN;

SELECT SYSTEM$DISABLE_BEHAVIOR_CHANGE_BUNDLE('2025_04');

ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';



CREATE OR REPLACE WAREHOUSE {{ env.EVENT_WAREHOUSE }}
WITH
  WAREHOUSE_SIZE = 'MEDIUM'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;


use warehouse {{ env.EVENT_WAREHOUSE }};

-----make listings available in chosen region -----

CALL SYSTEM$REQUEST_LISTING_AND_WAIT('GZTYZ1US93D', 60);

----- Disable mandatory MFA -----
USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS policy_db;
USE DATABASE policy_db;

CREATE SCHEMA IF NOT EXISTS policies;
USE SCHEMA policies;

CREATE AUTHENTICATION POLICY IF NOT EXISTS event_authentication_policy;

ALTER AUTHENTICATION POLICY event_authentication_policy SET
  MFA_ENROLLMENT=OPTIONAL
  CLIENT_TYPES = ('ALL')
  AUTHENTICATION_METHODS = ('ALL');

EXECUTE IMMEDIATE $$
    BEGIN
        ALTER ACCOUNT SET AUTHENTICATION POLICY event_authentication_policy;
    EXCEPTION
        WHEN STATEMENT_ERROR THEN
            RETURN SQLERRM;
    END;
$$
;
---------------------------------


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

-- Create the users
use role USERADMIN;
create user IF NOT EXISTS {{ env.EVENT_USER_NAME }}
    PASSWORD = '{{ env.EVENT_USER_PASSWORD }}'
    LOGIN_NAME = {{ env.EVENT_USER_NAME }}
    FIRST_NAME = '{{ env.EVENT_USER_FIRST_NAME }}'
    LAST_NAME = '{{ env.EVENT_USER_LAST_NAME }}'
    MUST_CHANGE_PASSWORD = false
    TYPE = PERSON;
create user IF NOT EXISTS {{ env.EVENT_ADMIN_NAME }}
    PASSWORD = '{{ env.EVENT_ADMIN_PASSWORD }}'
    LOGIN_NAME = {{ env.EVENT_ADMIN_NAME }}
    FIRST_NAME = 'EVENT'
    LAST_NAME = 'ADMIN'
    MUST_CHANGE_PASSWORD = false
    TYPE = PERSON;

-- Ensure the user can use the role and warehouse
use role SECURITYADMIN;
grant role {{ env.EVENT_ATTENDEE_ROLE }} to user {{ env.EVENT_USER_NAME }};
grant role ACCOUNTADMIN to user {{ env.EVENT_USER_NAME }};
grant USAGE on warehouse {{ env.EVENT_WAREHOUSE }} to role {{ env.EVENT_ATTENDEE_ROLE }};

-- Ensure ADMIN can use ACCOUNTADMIN role
grant role ACCOUNTADMIN to user {{ env.EVENT_ADMIN_NAME }};
grant role ACCOUNTADMIN to user {{env.EVENT_USER_NAME }};

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

create database IF NOT EXISTS {{ env.DATAOPS_DATABASE }};
create schema IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.EVENT_SCHEMA }};
create schema IF NOT EXISTS {{env.DATAOPS_DATABASE }}.{{env.DOCUMENT_AI_SCHEMA}};
create schema IF NOT EXISTS {{env.DATAOPS_DATABASE }}.{{env.CORTEX_ANALYST_SCHEMA}};



CREATE OR REPLACE TABLE {{env.DATAOPS_DATABASE }}.{{env.DOCUMENT_AI_SCHEMA}}.INFOGRAPHICS AS SELECT * FROM 

ORGDATACLOUD$INTERNAL$TRANSCRIPTS_FROM_EARNINGS_CALLS.ACCELERATE_WITH_AI_DOC_AI.INFOGRAPHICS;



CREATE OR REPLACE TABLE {{env.DATAOPS_DATABASE }}.{{env.DOCUMENT_AI_SCHEMA}}.DOCUMENT_AI_PROCESSED AS SELECT * FROM 
ORGDATACLOUD$INTERNAL$TRANSCRIPTS_FROM_EARNINGS_CALLS.ACCELERATE_WITH_AI_DOC_AI.DOCUMENT_AI_PROCESSED;


CREATE OR REPLACE TABLE {{ env.DATAOPS_DATABASE }}.{{ env.EVENT_SCHEMA }}.EARNINGS_CALL_TRANSCRIPT AS 

SELECT * FROM ORGDATACLOUD$INTERNAL$TRANSCRIPTS_FROM_EARNINGS_CALLS.TRANSCRIPTS.EARNINGS_TRANSCRIPTS;

CREATE OR REPLACE VIEW {{ env.DATAOPS_DATABASE }}.{{ env.EVENT_SCHEMA }}.STOCK_PRICE_TIMESERIES 

AS SELECT * FROM ORGDATACLOUD$INTERNAL$TRANSCRIPTS_FROM_EARNINGS_CALLS.ACCELERATE_WITH_AI_DOC_AI.STOCK_PRICE_TIMESERIES;


-- If data sharing enambled, create a database from the share
{% if env.EVENT_DATA_SHARING == "true" %}
use role {{ env.EVENT_ATTENDEE_ROLE }};
create database if not exists {{ env.EVENT_SHARE }} from share {{ env.DATAOPS_SHARE_ACCOUNT | replace('-', '.') | upper }}.{{ env.EVENT_SHARE }};
grant imported privileges on database {{ env.EVENT_SHARE }} to role PUBLIC;
{% endif %}
