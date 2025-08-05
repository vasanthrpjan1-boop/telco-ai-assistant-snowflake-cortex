-- Configure Attendee Account for Telco
ALTER SESSION SET QUERY_TAG = '''{"origin":"sf_sit-is", "name":"Build an AI Assistant for Telecommunications using Cortex and Document AI", "version":{"major":1, "minor":0},"attributes":{"is_quickstart":0, "source":"sql"}}''';
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



-- =====================================================
-- TELCO INDUSTRY DATA SETUP
-- =====================================================

-- 1. NETWORK PERFORMANCE TABLE
CREATE OR REPLACE TABLE {{ env.DATAOPS_DATABASE }}.{{ env.EVENT_SCHEMA }}.NETWORK_PERFORMANCE (
    CELL_TOWER_ID VARCHAR(50),
    NETWORK_TYPE VARCHAR(20),
    REGION VARCHAR(50),
    MEASUREMENT_TIMESTAMP TIMESTAMP_NTZ,
    LATENCY_MS FLOAT,
    THROUGHPUT_MBPS FLOAT,
    PACKET_LOSS_PERCENT FLOAT,
    UPTIME_PERCENT FLOAT
);

-- Insert sample network performance data
INSERT INTO {{ env.DATAOPS_DATABASE }}.{{ env.EVENT_SCHEMA }}.NETWORK_PERFORMANCE VALUES
-- Northeast Region - 5G Towers
('TOWER_NYC_001', '5G', 'Northeast', '2024-01-15 14:30:00', 8.5, 1200.5, 0.05, 99.95),
('TOWER_NYC_001', '5G', 'Northeast', '2024-01-15 15:00:00', 9.2, 1180.3, 0.08, 99.92),
('TOWER_NYC_001', '5G', 'Northeast', '2024-01-15 15:30:00', 7.8, 1250.1, 0.03, 99.98),
('TOWER_BOS_015', '5G', 'Northeast', '2024-01-15 14:30:00', 12.1, 980.7, 0.12, 99.85),
('TOWER_BOS_015', '5G', 'Northeast', '2024-01-15 15:00:00', 11.5, 1050.2, 0.09, 99.88),
-- West Coast Region - 5G Towers  
('TOWER_LA_045', '5G', 'West_Coast', '2024-01-15 14:30:00', 10.2, 1100.8, 0.07, 99.90),
('TOWER_LA_045', '5G', 'West_Coast', '2024-01-15 15:00:00', 9.8, 1145.6, 0.06, 99.93),
('TOWER_SF_032', '5G', 'West_Coast', '2024-01-15 14:30:00', 13.5, 890.4, 0.15, 99.82),
('TOWER_SF_032', '5G', 'West_Coast', '2024-01-15 15:00:00', 12.8, 920.1, 0.11, 99.86),
-- Midwest Region - 4G LTE Towers
('TOWER_CHI_023', '4G_LTE', 'Midwest', '2024-01-15 14:30:00', 18.7, 450.3, 0.25, 99.70),
('TOWER_CHI_023', '4G_LTE', 'Midwest', '2024-01-15 15:00:00', 17.9, 485.7, 0.22, 99.75),
('TOWER_DET_041', '4G_LTE', 'Midwest', '2024-01-15 14:30:00', 22.1, 380.9, 0.30, 99.65),
('TOWER_DET_041', '4G_LTE', 'Midwest', '2024-01-15 15:00:00', 20.5, 410.2, 0.28, 99.68),
-- Rural Areas - 3G Network
('TOWER_RUR_101', '3G', 'Rural_South', '2024-01-15 14:30:00', 45.2, 85.3, 1.2, 98.90),
('TOWER_RUR_101', '3G', 'Rural_South', '2024-01-15 15:00:00', 48.7, 78.9, 1.5, 98.85),
('TOWER_RUR_205', '3G', 'Rural_West', '2024-01-15 14:30:00', 52.1, 72.1, 1.8, 98.75),
('TOWER_RUR_205', '3G', 'Rural_West', '2024-01-15 15:00:00', 49.3, 81.4, 1.6, 98.80);

-- 2. CUSTOMER USAGE TABLE
CREATE OR REPLACE TABLE {{ env.DATAOPS_DATABASE }}.{{ env.EVENT_SCHEMA }}.CUSTOMER_USAGE (
    CUSTOMER_ID VARCHAR(20),
    SERVICE_PLAN VARCHAR(30),
    DEVICE_TYPE VARCHAR(20),
    USAGE_DATE DATE,
    DATA_USAGE_GB FLOAT,
    VOICE_MINUTES INTEGER,
    SMS_COUNT INTEGER,
    MONTHLY_BILL_AMOUNT FLOAT
);

-- Insert sample customer usage data
INSERT INTO {{ env.DATAOPS_DATABASE }}.{{ env.EVENT_SCHEMA }}.CUSTOMER_USAGE VALUES
-- Premium 5G Customers
('CUST_1001234', 'UNLIMITED_5G', 'SMARTPHONE', '2024-01-15', 45.8, 680, 245, 120.75),
('CUST_1001234', 'UNLIMITED_5G', 'SMARTPHONE', '2024-01-16', 52.3, 720, 198, 120.75),
('CUST_1001234', 'UNLIMITED_5G', 'SMARTPHONE', '2024-01-17', 38.9, 590, 312, 120.75),
('CUST_2005678', 'UNLIMITED_5G', 'SMARTPHONE', '2024-01-15', 62.1, 450, 156, 125.99),
('CUST_2005678', 'UNLIMITED_5G', 'SMARTPHONE', '2024-01-16', 58.7, 520, 189, 125.99),
('CUST_3009012', 'PREMIUM_DATA', 'TABLET', '2024-01-15', 28.4, 0, 0, 85.50),
('CUST_3009012', 'PREMIUM_DATA', 'TABLET', '2024-01-16', 31.2, 0, 0, 85.50),
-- Standard Plan Customers
('CUST_4012345', 'PREMIUM_DATA', 'SMARTPHONE', '2024-01-15', 25.6, 320, 89, 65.50),
('CUST_4012345', 'PREMIUM_DATA', 'SMARTPHONE', '2024-01-16', 22.8, 380, 112, 65.50),
('CUST_5067890', 'BASIC_MOBILE', 'SMARTPHONE', '2024-01-15', 12.3, 450, 150, 45.99),
('CUST_5067890', 'BASIC_MOBILE', 'SMARTPHONE', '2024-01-16', 15.7, 390, 134, 45.99),
-- IoT Device Customers
('CUST_6078901', 'IOT_CONNECT', 'IOT_DEVICE', '2024-01-15', 2.1, 0, 0, 15.99),
('CUST_6078901', 'IOT_CONNECT', 'IOT_DEVICE', '2024-01-16', 1.8, 0, 0, 15.99),
('CUST_7089012', 'IOT_CONNECT', 'IOT_DEVICE', '2024-01-15', 3.4, 0, 0, 15.99),
('CUST_8090123', 'FAMILY_PLAN', 'SMARTPHONE', '2024-01-15', 35.2, 890, 267, 95.99),
('CUST_9001234', 'STUDENT_PLAN', 'SMARTPHONE', '2024-01-15', 18.9, 245, 456, 35.99);

-- 3. SERVICE QUALITY METRICS TABLE
CREATE OR REPLACE TABLE {{ env.DATAOPS_DATABASE }}.{{ env.EVENT_SCHEMA }}.SERVICE_QUALITY_METRICS (
    SERVICE_TYPE VARCHAR(30),
    GEOGRAPHIC_AREA VARCHAR(20),
    QUALITY_MEASUREMENT_TIME TIMESTAMP_NTZ,
    CALL_DROP_RATE FLOAT,
    DATA_SUCCESS_RATE FLOAT,
    CUSTOMER_SATISFACTION_SCORE FLOAT
);

INSERT INTO {{ env.DATAOPS_DATABASE }}.{{ env.EVENT_SCHEMA }}.SERVICE_QUALITY_METRICS VALUES
('VOICE_CALL', 'URBAN', '2024-01-15 09:15:00', 0.5, 98.5, 4.2),
('VOICE_CALL', 'URBAN', '2024-01-15 09:30:00', 0.8, 98.2, 4.1),
('VOICE_CALL', 'URBAN', '2024-01-15 09:45:00', 0.3, 98.8, 4.4),
('DATA_SESSION', 'SUBURBAN', '2024-01-15 09:15:00', 0.0, 97.8, 3.8),
('DATA_SESSION', 'SUBURBAN', '2024-01-15 09:30:00', 0.0, 98.1, 3.9),
('DATA_SESSION', 'SUBURBAN', '2024-01-15 09:45:00', 0.0, 97.5, 3.7),
('VIDEO_STREAMING', 'RURAL', '2024-01-15 09:15:00', 0.0, 95.2, 3.2),
('VIDEO_STREAMING', 'RURAL', '2024-01-15 09:30:00', 0.0, 94.8, 3.1),
('VIDEO_STREAMING', 'RURAL', '2024-01-15 09:45:00', 0.0, 96.1, 3.4),
('VIDEO_STREAMING', 'URBAN', '2024-01-15 09:15:00', 0.0, 99.1, 4.6),
('VIDEO_STREAMING', 'URBAN', '2024-01-15 09:30:00', 0.0, 98.9, 4.5),
('VIDEO_STREAMING', 'URBAN', '2024-01-15 09:45:00', 0.0, 99.3, 4.7);

-- 4. NETWORK INCIDENTS TABLE
CREATE OR REPLACE TABLE {{ env.DATAOPS_DATABASE }}.{{ env.EVENT_SCHEMA }}.NETWORK_INCIDENTS (
    INCIDENT_ID VARCHAR(20),
    INCIDENT_TYPE VARCHAR(30),
    SEVERITY_LEVEL VARCHAR(20),
    AFFECTED_REGION VARCHAR(30),
    INCIDENT_START_TIME TIMESTAMP_NTZ,
    INCIDENT_END_TIME TIMESTAMP_NTZ,
    CUSTOMERS_AFFECTED INTEGER,
    DURATION_MINUTES INTEGER,
    REVENUE_IMPACT FLOAT
);

INSERT INTO {{ env.DATAOPS_DATABASE }}.{{ env.EVENT_SCHEMA }}.NETWORK_INCIDENTS VALUES
('INC_2024_001', 'HARDWARE_FAILURE', 'CRITICAL', 'Northeast', '2024-01-15 08:30:00', '2024-01-15 10:15:00', 15000, 105, 25000.50),
('INC_2024_002', 'NETWORK_CONGESTION', 'HIGH', 'West_Coast', '2024-01-15 14:15:00', '2024-01-15 16:30:00', 8900, 135, 18500.25),
('INC_2024_003', 'SOFTWARE_BUG', 'MEDIUM', 'Midwest', '2024-01-15 20:45:00', '2024-01-15 22:20:00', 5800, 95, 8900.75),
('INC_2024_045', 'POWER_OUTAGE', 'CRITICAL', 'Texas', '2024-01-16 06:20:00', '2024-01-16 09:45:00', 32000, 205, 45000.75),
('INC_2024_046', 'EQUIPMENT_MAINTENANCE', 'LOW', 'California', '2024-01-16 02:00:00', '2024-01-16 04:30:00', 1200, 150, 2500.00),
('INC_2024_089', 'FIBER_CUT', 'HIGH', 'Florida', '2024-01-14 11:30:00', '2024-01-14 14:15:00', 12500, 165, 22000.30),
('INC_2024_090', 'CONFIGURATION_ERROR', 'MEDIUM', 'Ohio', '2024-01-14 16:45:00', '2024-01-14 18:20:00', 3400, 95, 5800.15);

-- 5. NETWORK REPORTS PARSED (Document AI Results)
CREATE OR REPLACE TABLE {{env.DATAOPS_DATABASE }}.{{env.DOCUMENT_AI_SCHEMA}}.NETWORK_REPORTS_PARSED (
    REPORT_TYPE VARCHAR(30),
    SOURCE_SYSTEM VARCHAR(50),
    QUARTER VARCHAR(5),
    REPORT_DATE DATE,
    NETWORK_AVAILABILITY_PERCENT DECIMAL(5,2),
    TOTAL_SUBSCRIBERS INTEGER,
    PEAK_TRAFFIC_GBPS DECIMAL(10,2),
    INCIDENT_COUNT INTEGER,
    AVERAGE_RESOLUTION_TIME_HOURS DECIMAL(6,2)
);

INSERT INTO {{env.DATAOPS_DATABASE }}.{{env.DOCUMENT_AI_SCHEMA}}.NETWORK_REPORTS_PARSED VALUES
('PERFORMANCE_DASHBOARD', 'NETWORK_MONITORING_SYSTEM', 'Q1', '2024-01-31', 99.95, 5250000, 850.25, 25, 2.5),
('PERFORMANCE_DASHBOARD', 'NETWORK_MONITORING_SYSTEM', 'Q2', '2024-04-30', 99.87, 5875000, 920.75, 18, 1.8),
('PERFORMANCE_DASHBOARD', 'NETWORK_MONITORING_SYSTEM', 'Q3', '2024-07-31', 99.92, 6100000, 1050.50, 32, 3.2),
('INCIDENT_REPORT', 'INCIDENT_MANAGEMENT_TOOL', 'Q1', '2024-01-31', 99.85, 5250000, 800.00, 45, 3.1),
('INCIDENT_REPORT', 'INCIDENT_MANAGEMENT_TOOL', 'Q2', '2024-04-30', 99.90, 5875000, 850.25, 38, 2.7),
('MAINTENANCE_LOG', 'MAINTENANCE_TRACKER', 'Q1', '2024-01-31', 99.98, 5250000, 750.00, 12, 1.5),
('MAINTENANCE_LOG', 'MAINTENANCE_TRACKER', 'Q2', '2024-04-30', 99.95, 5875000, 800.50, 15, 1.8);

-- 6. NETWORK DOCUMENTATION FOR CORTEX SEARCH
CREATE OR REPLACE TABLE {{ env.DATAOPS_DATABASE }}.{{ env.EVENT_SCHEMA }}.NETWORK_DOCUMENTATION (
    DOCUMENT_ID VARCHAR(50),
    DOCUMENT_TYPE VARCHAR(30),
    TITLE VARCHAR(200),
    CONTENT TEXT,
    TAGS VARCHAR(500),
    CREATED_DATE DATE
);

INSERT INTO {{ env.DATAOPS_DATABASE }}.{{ env.EVENT_SCHEMA }}.NETWORK_DOCUMENTATION VALUES
('DOC_001', 'TROUBLESHOOTING', '5G Network Latency Issues', 
'When experiencing high latency on 5G networks, first check the signal strength and tower proximity. Common causes include network congestion during peak hours, interference from other electronic devices, and suboptimal tower configuration. Resolution steps: 1) Check tower load balancing, 2) Verify RF settings, 3) Monitor for interference sources, 4) Consider traffic shaping policies.', 
'5G,latency,troubleshooting,network,performance', '2024-01-01'),
('DOC_002', 'BEST_PRACTICES', 'Customer Data Usage Optimization',
'Best practices for optimizing customer data usage include implementing traffic prioritization, enabling data compression, and providing usage alerts. Monitor customer usage patterns to identify potential service upgrades and implement fair usage policies to ensure network quality for all subscribers.',
'customer,data,usage,optimization,traffic', '2024-01-02'),
('DOC_003', 'INCIDENT_RESPONSE', 'Critical Incident Response Protocol',
'For critical network incidents affecting more than 10,000 customers: 1) Immediate escalation to Network Operations Center, 2) Customer communication within 15 minutes, 3) Engage vendor support if hardware-related, 4) Implement emergency routing if available, 5) Post-incident analysis within 24 hours.',
'incident,response,critical,protocol,customers', '2024-01-03'),
('DOC_004', 'MAINTENANCE', 'Planned Maintenance Windows',
'Standard maintenance windows are scheduled during low-traffic periods (2 AM - 6 AM local time). All maintenance must be approved 48 hours in advance, with customer notifications sent 24 hours prior. Emergency maintenance procedures allow for immediate action when service availability is at risk.',
'maintenance,windows,planning,notifications,emergency', '2024-01-04'),
('DOC_005', 'NETWORK_PLANNING', '5G Network Expansion Guidelines',
'5G network expansion should prioritize high-density urban areas and business districts. Site selection criteria include population density, existing infrastructure, fiber backhaul availability, and regulatory compliance. Expected coverage radius for 5G sites is 1-3 km in urban areas, 5-10 km in suburban areas.',
'5G,expansion,planning,coverage,infrastructure', '2024-01-05');


-- If data sharing enambled, create a database from the share
{% if env.EVENT_DATA_SHARING == "true" %}
use role {{ env.EVENT_ATTENDEE_ROLE }};
create database if not exists {{ env.EVENT_SHARE }} from share {{ env.DATAOPS_SHARE_ACCOUNT | replace('-', '.') | upper }}.{{ env.EVENT_SHARE }};
grant imported privileges on database {{ env.EVENT_SHARE }} to role PUBLIC;
{% endif %}
