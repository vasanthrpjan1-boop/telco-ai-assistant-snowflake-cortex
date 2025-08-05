import streamlit as st
import json
import _snowflake
import re
from snowflake.snowpark.context import get_active_session
logo = 'snowflake_logo_color_rgb.svg'
session = get_active_session()
model = 'llama3.3-70b'
st.set_page_config(layout="wide")
with open('extra.css') as ab:
    st.markdown(f"<style>{ab.read()}</style>", unsafe_allow_html=True)

st.logo(logo)
session = get_active_session()

API_ENDPOINT = "/api/v2/cortex/agent:run"
API_TIMEOUT = 50000  # in milliseconds

CORTEX_SEARCH_SERVICES = "DEFAULT_SCHEMA.NETWORK_DOCUMENTATION"
SEMANTIC_MODELS = "@CORTEX_ANALYST.CORTEX_ANALYST/telco_semantic_model.yaml"

def run_snowflake_query(query):
    """Run Snowflake SQL Query"""
    try:
        df = session.sql(query.replace(';',''))
        return df

    except Exception as e:
        st.error(f"Error executing SQL: {str(e)}")
        return None, None

def snowflake_api_call(query: str, limit: int = 10):
    """Make an Agent API Call"""
    payload = {
        "model": f"{model}",
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": query
                    }
                ]
            }
        ],
        "tools": [
            {
                "tool_spec": {
                    "type": "cortex_analyst_text_to_sql",
                    "name": "analyst1"
                }
            },
            {
                "tool_spec": {
                    "type": "cortex_search",
                    "name": "search1"
                }
            }
        ],
        "tool_resources": {
            "analyst1": {"semantic_model_file": SEMANTIC_MODELS},
            "search1": {
                "name": CORTEX_SEARCH_SERVICES,
                "max_results": 10,
                "id_column": "DOCUMENT_ID"
            }
        }
    }
    
    try:
        resp = _snowflake.send_snow_api_request(
            "POST",  # method
            API_ENDPOINT,  # path
            {},  # headers
            {},  # params
            payload,  # body
            None,  # request_guid
            API_TIMEOUT,  # timeout in milliseconds,
        )
        
        if resp["status"] != 200:
            st.error(f"❌ HTTP Error: {resp['status']} - {resp.get('reason', 'Unknown reason')}")
            st.error(f"Response details: {resp}")
            return None
        
        try:
            response_content = json.loads(resp["content"])
        except json.JSONDecodeError:
            st.error("❌ Failed to parse API response. The server may have returned an invalid JSON format.")
            st.error(f"Raw response: {resp['content'][:200]}...")
            return None
            
        return response_content
            
    except Exception as e:
        st.error(f"Error making request: {str(e)}")
        return None

def process_sse_response(response):
    """Process SSE response"""
    text = ""
    sql = ""
    citations = []
    
    if not response:
        return text, sql, citations
    if isinstance(response, str):
        return text, sql, citations
    try:
        for event in response:
            if event.get('event') == "message.delta":
                data = event.get('data', {})
                delta = data.get('delta', {})
                
                for content_item in delta.get('content', []):
                    content_type = content_item.get('type')
                    if content_type == "tool_results":
                        tool_results = content_item.get('tool_results', {})
                        if 'content' in tool_results:
                            for result in tool_results['content']:
                                if result.get('type') == 'json':
                                    text += result.get('json', {}).get('text', '')
                                    search_results = result.get('json', {}).get('searchResults', [])
                                    for search_result in search_results:
                                        citations.append({'source_id':search_result.get('source_id',''), 'doc_id':search_result.get('doc_id', '')})
                                    sql = result.get('json', {}).get('sql', '')
                    if content_type == 'text':
                        text += content_item.get('text', '')
                            
    except json.JSONDecodeError as e:
        st.error(f"Error processing events: {str(e)}")
                
    except Exception as e:
        st.error(f"Error processing events: {str(e)}")
        
    return text, sql, citations

@st.cache_data
def execute_cortex_complete_sql(prompt):
    """
    Execute Cortex Complete using the SQL API
    """
    cmd = "SELECT snowflake.cortex.complete(?, ?) AS response"
    df_response = session.sql(cmd, params=[f"{model}", prompt]).collect()
    response_txt = df_response[0].RESPONSE
    return response_txt

@st.cache_data
def extract_python_code(text):
    """
    Extract only the Streamlit chart execution code from LLM output, including all arguments.
    """
    pattern = r"st\.(line_chart|bar_chart|scatter_chart)\((.*)\)"
    match = re.search(pattern, text, re.DOTALL)
    
    if match:
        code = f"st.{match.group(1)}({match.group(2)})"
        return code.strip()  # Ensure clean extraction
    return None  # Return None if no chart code is found

def replace_chart_function(chart_string, new_chart_type):
    return re.sub(r"st\.(\w+_chart)", f"st.{new_chart_type}", chart_string)

def get_network_status_summary():
    """Get a quick network status summary"""
    try:
        # Get latest network performance metrics
        query = """
        SELECT 
            AVG(uptime_percent) as avg_uptime,
            AVG(latency_ms) as avg_latency,
            COUNT(DISTINCT cell_tower_id) as active_towers,
            MAX(measurement_timestamp) as last_update
        FROM network_performance 
        WHERE measurement_timestamp >= DATEADD(hour, -1, CURRENT_TIMESTAMP())
        """
        result = run_snowflake_query(query)
        if result:
            return result.to_pandas().iloc[0]
    except:
        pass
    return None

def get_critical_incidents():
    """Get current critical incidents"""
    try:
        query = """
        SELECT incident_id, incident_type, affected_region, customers_affected
        FROM network_incidents 
        WHERE severity_level = 'CRITICAL' 
        AND incident_end_time IS NULL
        ORDER BY incident_start_time DESC
        LIMIT 5
        """
        result = run_snowflake_query(query)
        if result:
            return result.to_pandas()
    except:
        pass
    return None

def main():
    st.markdown('<h0black>SNOWFLAKE | </h0black><h0blue>TELCO NETWORK OPERATIONS</h0blue><BR>', unsafe_allow_html=True)

    # Sidebar for new chat and network status
    with st.sidebar:
        if st.button("NEW CONVERSATION", key="new_chat", type="secondary"):
            st.session_state.messages = []
            st.rerun()
        
        st.markdown("---")
        st.markdown("### 📊 **Network Status**")
        
        # Network status summary
        status_data = get_network_status_summary()
        if status_data is not None:
            col1, col2 = st.columns(2)
            with col1:
                st.metric("Network Uptime", f"{status_data['AVG_UPTIME']:.2f}%")
                st.metric("Active Towers", f"{status_data['ACTIVE_TOWERS']:,}")
            with col2:
                st.metric("Avg Latency", f"{status_data['AVG_LATENCY']:.1f}ms")
        
        # Critical incidents
        st.markdown("### 🚨 **Critical Incidents**")
        incidents = get_critical_incidents()
        if incidents is not None and not incidents.empty:
            for _, incident in incidents.iterrows():
                st.error(f"**{incident['INCIDENT_TYPE']}**\n{incident['AFFECTED_REGION']} - {incident['CUSTOMERS_AFFECTED']:,} customers affected")
        else:
            st.success("No critical incidents")
        
        st.markdown("---")
        st.markdown("### 🔧 **Quick Actions**")
        
        # Quick action buttons
        quick_queries = [
            "Show network performance by region",
            "What critical incidents happened today?",
            "Top 10 customers by data usage",
            "Network latency trends last hour",
            "5G network performance summary"
        ]
        
        for query in quick_queries:
            if st.button(f"📋 {query}", key=f"quick_{hash(query)}", use_container_width=True):
                st.session_state.quick_query = query
                st.rerun()

    # Handle quick query
    if hasattr(st.session_state, 'quick_query'):
        query = st.session_state.quick_query
        delattr(st.session_state, 'quick_query')
        
        # Add to messages and process
        if 'messages' not in st.session_state:
            st.session_state.messages = []
        
        st.session_state.messages.append({"role": "user", "content": query})
        
        with st.spinner("Processing your request..."):
            response = snowflake_api_call(query, 1)
            text, sql, citations = process_sse_response(response)
            
            if text:
                text = text.replace("【†", "[").replace("†】", "]")
                st.session_state.messages.append({"role": "assistant", "content": text})

    # Initialize session state
    if 'messages' not in st.session_state:
        st.session_state.messages = []

    # Display chat messages
    for message in st.session_state.messages:
        with st.chat_message(message['role'], avatar='🔧' if message['role'] == 'assistant' else '👨‍💼'):
            st.markdown(message['content'].replace("•", "\n\n"))

    # Chat input
    if query := st.chat_input("Ask me about network operations, customer usage, or incidents..."):
        # Add user message to chat
        with st.chat_message("user", avatar="👨‍💼"):
            st.markdown(query)
        st.session_state.messages.append({"role": "user", "content": query})
        
        # Get response from API
        with st.spinner("Analyzing network data..."):
            response = snowflake_api_call(query, 1)
            text, sql, citations = process_sse_response(response)
            
            # Add assistant response to chat
            if text:
                text = text.replace("【†", "[")
                text = text.replace("†】", "]")
                st.session_state.messages.append({"role": "assistant", "content": text})
                
                with st.chat_message("assistant", avatar="🔧"):
                    st.markdown(text.replace("•", "\n\n"))
                    
                    # Display citations if present
                    if citations:
                        st.markdown('<h0blue>DOCUMENTATION REFERENCES</h0blue><BR>', unsafe_allow_html=True)
                        for citation in citations:
                            doc_id = citation.get("doc_id", "")
                            if doc_id:
                                query_ref = f"SELECT CONTENT FROM DEFAULT_SCHEMA.NETWORK_DOCUMENTATION WHERE DOCUMENT_ID = '{doc_id}'"
                                result = run_snowflake_query(query_ref)
                                if result:
                                    result_df = result.to_pandas()
                                    if not result_df.empty:
                                        doc_content = result_df.iloc[0, 0]
                                    else:
                                        doc_content = "Document content not available"
                                else:
                                    doc_content = "Document content not available"
                    
                                with st.expander(f"📄 [{citation.get('source_id', 'Unknown Source')}]"):
                                    st.write(doc_content)
        
            # Display SQL if present
            if sql:
                st.markdown('<h0blue>NETWORK DATA ANALYSIS</h0blue><BR>', unsafe_allow_html=True)
                with st.expander("📊 SQL Query", expanded=True):
                    st.code(sql, language="sql")

                with st.expander("📈 Data Visualization", expanded=True):
                    try:
                        analysis_results = run_snowflake_query(sql).to_pandas()

                        if len(analysis_results.index) > 1:
                            data_tab, suggested_plot, line_tab, bar_tab, scatter_tab = st.tabs(
                             ["📋 Data", "🎯 Suggested Plot", "📈 Line Chart", "📊 Bar Chart","🔷 Scatter Chart"]
                         )
                            data_tab.dataframe(analysis_results, use_container_width=True)
                            
                            if len(analysis_results.columns) > 1:
                                analysis_results = analysis_results.set_index(analysis_results.columns[0])
                            
                            with suggested_plot:
                                try:
                                    prompt = f'''
                                                Create a streamlit plot using st.line_chart OR st.bar_chart OR st.scatter_chart 
                                                based on the dataframe called "analysis_results" with given columns: {analysis_results.columns}.
                                                Give me ONLY the code itself based on the columns. 
                                                Select only columns relevant to the query - {query}.
                                                Do not create fake data.
                                                Do not include imports.
                                                Do not include any columns that are not provided.
                                                Only return the best chart for the data.
                                                Choose only 1 value for X and 1 value for Y. for each chart, add color='#29B5E8'
                                                For telco data, use appropriate chart types (line charts for time series, bar charts for comparisons).
                                                '''
                                    code = execute_cortex_complete_sql(prompt)
                                    execution_code = extract_python_code(code)
                                    
                                    if execution_code:
                                        st.code(execution_code, language="python", line_numbers=False)
                                        exec(execution_code)
                                except Exception as e:
                                    st.error(f"Could not generate chart: {str(e)}")
                            
                            with line_tab:
                                try:
                                    if execution_code:
                                        exec(replace_chart_function(execution_code, 'line_chart'))
                                except:
                                    st.line_chart(analysis_results, color='#29B5E8')
                            
                            with bar_tab:
                                try: 
                                    if execution_code:
                                        exec(replace_chart_function(execution_code, 'bar_chart'))
                                except:
                                    st.bar_chart(analysis_results, color='#29B5E8')
                                    
                            with scatter_tab:
                                try: 
                                    if execution_code:
                                        exec(replace_chart_function(execution_code, 'scatter_chart'))
                                except:
                                    pass
                        else:
                            st.dataframe(analysis_results, use_container_width=True)
                    except Exception as e:
                        st.error(f"Error processing data: {str(e)}")

if __name__ == "__main__":
    main()

# Sample Questions to try:
    
# - What is the average network latency by region in the last hour?
# - Show me critical incidents from the past 24 hours
# - Which customers are using the most data this month?
# - What is the 5G network performance compared to 4G?
# - How many network incidents occurred this week by type?
# - Show network uptime trends for the Northeast region
# - What is the average customer bill amount by service plan?