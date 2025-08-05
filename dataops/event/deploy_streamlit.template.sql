ALTER SESSION SET QUERY_TAG = '''{"origin":"sf_sit-is", "name":"Build an AI Assistant for Telecommunications using Cortex and Document AI", "version":{"major":1, "minor":0},"attributes":{"is_quickstart":0, "source":"sql"}}''';
use role {{ env.EVENT_ATTENDEE_ROLE }};

create schema if not exists {{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }};
-----create Telco streamlit stages
CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.TELCO_NETWORK_OPS DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');
CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.TELCO_CUSTOMER_ANALYTICS DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');
CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.CORTEX_CHAT DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');


------put Telco streamlit files in stages

-- Telco Network Operations App
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/telco_network_ops/app.py @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.TELCO_NETWORK_OPS auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/telco_network_ops/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.TELCO_NETWORK_OPS auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/telco_network_ops/config.toml @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.TELCO_NETWORK_OPS/.streamlit auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/logos/snowflake_logo_color_rgb.svg @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.TELCO_NETWORK_OPS/ auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/homepage/docs/stylesheets/extra.css @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.TELCO_NETWORK_OPS/ auto_compress = false overwrite = true;

-- Telco Customer Analytics App
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/telco_customer_analytics/app.py @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.TELCO_CUSTOMER_ANALYTICS auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/telco_customer_analytics/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.TELCO_CUSTOMER_ANALYTICS auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/telco_customer_analytics/config.toml @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.TELCO_CUSTOMER_ANALYTICS/.streamlit auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/logos/snowflake_logo_color_rgb.svg @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.TELCO_CUSTOMER_ANALYTICS/ auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/homepage/docs/stylesheets/extra.css @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.TELCO_CUSTOMER_ANALYTICS/ auto_compress = false overwrite = true;



-- Cortex Chat App (updated for Telco)
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/cortex_chat/app.py @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.CORTEX_CHAT auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/cortex_chat/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.CORTEX_CHAT auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/logos/snowflake_logo_color_rgb.svg @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.CORTEX_CHAT/ auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/homepage/docs/stylesheets/extra.css @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.CORTEX_CHAT/ auto_compress = false overwrite = true;


-----CREATE TELCO STREAMLIT APPS

CREATE OR REPLACE STREAMLIT {{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.TELCO_NETWORK_OPERATIONS
ROOT_LOCATION = '@{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.TELCO_NETWORK_OPS'
MAIN_FILE = 'app.py'
QUERY_WAREHOUSE = '{{ env.EVENT_WAREHOUSE }}'
COMMENT = '''{"origin":"sf_sit-is", "name":"Build an AI Assistant for Telecommunications using Cortex and Document AI", "version":{"major":1, "minor":0},"attributes":{"is_quickstart":0, "source":"streamlit", "app_type":"network_operations"}}''';

CREATE OR REPLACE STREAMLIT {{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.TELCO_CUSTOMER_ANALYTICS
ROOT_LOCATION = '@{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.TELCO_CUSTOMER_ANALYTICS'
MAIN_FILE = 'app.py'
QUERY_WAREHOUSE = '{{ env.EVENT_WAREHOUSE }}'
COMMENT = '''{"origin":"sf_sit-is", "name":"Build an AI Assistant for Telecommunications using Cortex and Document AI", "version":{"major":1, "minor":0},"attributes":{"is_quickstart":0, "source":"streamlit", "app_type":"customer_analytics"}}''';



CREATE OR REPLACE STREAMLIT {{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.TELCO_CORTEX_CHAT
ROOT_LOCATION = '@{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.CORTEX_CHAT'
MAIN_FILE = 'app.py'
QUERY_WAREHOUSE = '{{ env.EVENT_WAREHOUSE }}'
COMMENT = '''{"origin":"sf_sit-is", "name":"Build an AI Assistant for Telecommunications using Cortex and Document AI", "version":{"major":1, "minor":0},"attributes":{"is_quickstart":0, "source":"streamlit", "app_type":"telco_chat"}}''';


