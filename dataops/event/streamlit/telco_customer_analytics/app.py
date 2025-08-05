import streamlit as st
import json
import _snowflake
import re
import pandas as pd
from snowflake.snowpark.context import get_active_session
import plotly.express as px
import plotly.graph_objects as go

logo = 'snowflake_logo_color_rgb.svg'
session = get_active_session()
model = 'llama3.3-70b'
st.set_page_config(layout="wide", page_title="Telco Customer Analytics")

with open('extra.css') as ab:
    st.markdown(f"<style>{ab.read()}</style>", unsafe_allow_html=True)

st.logo(logo)

API_ENDPOINT = "/api/v2/cortex/agent:run"
API_TIMEOUT = 50000

CORTEX_SEARCH_SERVICES = "DEFAULT_SCHEMA.CUSTOMER_DOCUMENTATION"
SEMANTIC_MODELS = "@CORTEX_ANALYST.CORTEX_ANALYST/telco_semantic_model.yaml"

def run_snowflake_query(query):
    """Run Snowflake SQL Query"""
    try:
        df = session.sql(query.replace(';',''))
        return df
    except Exception as e:
        st.error(f"Error executing SQL: {str(e)}")
        return None

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
            "POST", API_ENDPOINT, {}, {}, payload, None, API_TIMEOUT
        )
        
        if resp["status"] != 200:
            st.error(f"❌ HTTP Error: {resp['status']} - {resp.get('reason', 'Unknown reason')}")
            return None
        
        try:
            response_content = json.loads(resp["content"])
        except json.JSONDecodeError:
            st.error("❌ Failed to parse API response.")
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
                            
    except Exception as e:
        st.error(f"Error processing events: {str(e)}")
        
    return text, sql, citations

def get_customer_overview():
    """Get customer overview metrics"""
    try:
        query = """
        SELECT 
            COUNT(DISTINCT customer_id) as total_customers,
            AVG(monthly_bill_amount) as avg_monthly_bill,
            SUM(data_usage_gb) as total_data_usage,
            COUNT(DISTINCT service_plan) as active_plans
        FROM customer_usage 
        WHERE usage_date >= DATEADD(month, -1, CURRENT_DATE())
        """
        result = run_snowflake_query(query)
        if result:
            return result.to_pandas().iloc[0]
    except:
        pass
    return None

def get_top_service_plans():
    """Get top service plans by customer count"""
    try:
        query = """
        SELECT 
            service_plan,
            COUNT(DISTINCT customer_id) as customer_count,
            AVG(monthly_bill_amount) as avg_bill
        FROM customer_usage 
        WHERE usage_date >= DATEADD(month, -1, CURRENT_DATE())
        GROUP BY service_plan
        ORDER BY customer_count DESC
        LIMIT 5
        """
        result = run_snowflake_query(query)
        if result:
            return result.to_pandas()
    except:
        pass
    return None

def get_usage_trends():
    """Get data usage trends"""
    try:
        query = """
        SELECT 
            usage_date,
            AVG(data_usage_gb) as avg_daily_usage,
            COUNT(DISTINCT customer_id) as active_customers
        FROM customer_usage 
        WHERE usage_date >= DATEADD(day, -30, CURRENT_DATE())
        GROUP BY usage_date
        ORDER BY usage_date
        """
        result = run_snowflake_query(query)
        if result:
            return result.to_pandas()
    except:
        pass
    return None

def create_plan_distribution_chart(df):
    """Create service plan distribution chart"""
    if df is not None and not df.empty:
        fig = px.pie(df, values='CUSTOMER_COUNT', names='SERVICE_PLAN', 
                     title='Customer Distribution by Service Plan',
                     color_discrete_sequence=px.colors.qualitative.Set3)
        fig.update_traces(textposition='inside', textinfo='percent+label')
        return fig
    return None

def create_usage_trend_chart(df):
    """Create usage trend chart"""
    if df is not None and not df.empty:
        fig = go.Figure()
        fig.add_trace(go.Scatter(x=df['USAGE_DATE'], y=df['AVG_DAILY_USAGE'],
                                mode='lines+markers', name='Avg Daily Usage (GB)',
                                line=dict(color='#29B5E8', width=3)))
        fig.update_layout(title='Daily Data Usage Trends (Last 30 Days)',
                         xaxis_title='Date',
                         yaxis_title='Average Data Usage (GB)',
                         template='plotly_white')
        return fig
    return None

def main():
    st.markdown('<h0black>SNOWFLAKE | </h0black><h0blue>TELCO CUSTOMER ANALYTICS</h0blue><BR>', unsafe_allow_html=True)

    # Create main dashboard layout
    tab1, tab2, tab3 = st.tabs(["📊 Dashboard", "💬 AI Assistant", "📈 Advanced Analytics"])
    
    with tab1:
        st.markdown("### 📊 **Customer Overview Dashboard**")
        
        # Get overview data
        overview = get_customer_overview()
        
        if overview is not None:
            col1, col2, col3, col4 = st.columns(4)
            
            with col1:
                st.metric("Total Customers", f"{overview['TOTAL_CUSTOMERS']:,}")
            with col2:
                st.metric("Avg Monthly Bill", f"${overview['AVG_MONTHLY_BILL']:.2f}")
            with col3:
                st.metric("Total Data Usage", f"{overview['TOTAL_DATA_USAGE']:,.1f} GB")
            with col4:
                st.metric("Active Plans", f"{overview['ACTIVE_PLANS']}")
        
        st.markdown("---")
        
        # Charts section
        col1, col2 = st.columns(2)
        
        with col1:
            st.markdown("#### 🥧 **Service Plan Distribution**")
            plan_data = get_top_service_plans()
            if plan_data is not None and not plan_data.empty:
                chart = create_plan_distribution_chart(plan_data)
                if chart:
                    st.plotly_chart(chart, use_container_width=True)
                
                st.markdown("**Plan Details:**")
                st.dataframe(plan_data, use_container_width=True)
        
        with col2:
            st.markdown("#### 📈 **Usage Trends**")
            trend_data = get_usage_trends()
            if trend_data is not None and not trend_data.empty:
                chart = create_usage_trend_chart(trend_data)
                if chart:
                    st.plotly_chart(chart, use_container_width=True)
                
                # Show recent trend
                if len(trend_data) >= 2:
                    recent_avg = trend_data['AVG_DAILY_USAGE'].tail(7).mean()
                    previous_avg = trend_data['AVG_DAILY_USAGE'].head(7).mean()
                    change = ((recent_avg - previous_avg) / previous_avg) * 100
                    
                    if change > 0:
                        st.success(f"📈 Usage increased by {change:.1f}% over last week")
                    else:
                        st.info(f"📉 Usage decreased by {abs(change):.1f}% over last week")

    with tab2:
        st.markdown("### 💬 **Customer Analytics AI Assistant**")
        
        # Sidebar for customer analytics
        with st.sidebar:
            st.markdown("### 🎯 **Quick Customer Insights**")
            
            customer_queries = [
                "Show top 10 customers by data usage",
                "What's the average bill by service plan?",
                "Which customers use the most voice minutes?",
                "Revenue analysis by customer segment",
                "Customer churn risk indicators",
                "Service plan upgrade recommendations"
            ]
            
            for query in customer_queries:
                if st.button(f"🔍 {query}", key=f"cust_{hash(query)}", use_container_width=True):
                    st.session_state.customer_query = query
                    st.rerun()

        # Handle quick query
        if hasattr(st.session_state, 'customer_query'):
            query = st.session_state.customer_query
            delattr(st.session_state, 'customer_query')
            
            # Add to messages and process
            if 'customer_messages' not in st.session_state:
                st.session_state.customer_messages = []
            
            st.session_state.customer_messages.append({"role": "user", "content": query})
            
            with st.spinner("Analyzing customer data..."):
                response = snowflake_api_call(query, 1)
                text, sql, citations = process_sse_response(response)
                
                if text:
                    text = text.replace("【†", "[").replace("†】", "]")
                    st.session_state.customer_messages.append({"role": "assistant", "content": text})

        # Initialize session state for customer chat
        if 'customer_messages' not in st.session_state:
            st.session_state.customer_messages = []

        # Display customer chat messages
        for message in st.session_state.customer_messages:
            with st.chat_message(message['role'], avatar='📊' if message['role'] == 'assistant' else '👤'):
                st.markdown(message['content'].replace("•", "\n\n"))

        # Customer chat input
        if query := st.chat_input("Ask about customer analytics, usage patterns, or billing..."):
            # Add user message to chat
            with st.chat_message("user", avatar="👤"):
                st.markdown(query)
            st.session_state.customer_messages.append({"role": "user", "content": query})
            
            # Get response from API
            with st.spinner("Analyzing customer data..."):
                response = snowflake_api_call(query, 1)
                text, sql, citations = process_sse_response(response)
                
                # Add assistant response to chat
                if text:
                    text = text.replace("【†", "[").replace("†】", "]")
                    st.session_state.customer_messages.append({"role": "assistant", "content": text})
                    
                    with st.chat_message("assistant", avatar="📊"):
                        st.markdown(text.replace("•", "\n\n"))
                        
                        # Display citations if present
                        if citations:
                            st.markdown('<h0blue>DOCUMENTATION REFERENCES</h0blue><BR>', unsafe_allow_html=True)
                            for citation in citations:
                                doc_id = citation.get("doc_id", "")
                                if doc_id:
                                    with st.expander(f"📄 [{citation.get('source_id', 'Unknown Source')}]"):
                                        st.write("Customer documentation content would appear here")
            
                # Display SQL if present
                if sql:
                    st.markdown('<h0blue>CUSTOMER DATA ANALYSIS</h0blue><BR>', unsafe_allow_html=True)
                    with st.expander("📊 SQL Query", expanded=True):
                        st.code(sql, language="sql")

                    with st.expander("📈 Customer Data Visualization", expanded=True):
                        try:
                            analysis_results = run_snowflake_query(sql).to_pandas()
                            
                            if not analysis_results.empty:
                                if len(analysis_results.index) > 1:
                                    data_tab, chart_tab = st.tabs(["📋 Data", "📊 Visualization"])
                                    
                                    with data_tab:
                                        st.dataframe(analysis_results, use_container_width=True)
                                    
                                    with chart_tab:
                                        # Smart chart selection based on data
                                        numeric_cols = analysis_results.select_dtypes(include=['number']).columns
                                        if len(numeric_cols) >= 1:
                                            if len(analysis_results.columns) >= 2:
                                                # Create appropriate chart based on data structure
                                                if 'DATE' in str(analysis_results.columns).upper() or 'TIME' in str(analysis_results.columns).upper():
                                                    st.line_chart(analysis_results.set_index(analysis_results.columns[0]), color='#29B5E8')
                                                else:
                                                    st.bar_chart(analysis_results.set_index(analysis_results.columns[0]), color='#29B5E8')
                                            else:
                                                st.bar_chart(analysis_results, color='#29B5E8')
                                else:
                                    st.dataframe(analysis_results, use_container_width=True)
                        except Exception as e:
                            st.error(f"Error processing customer data: {str(e)}")

    with tab3:
        st.markdown("### 📈 **Advanced Customer Analytics**")
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.markdown("#### 🎯 **Customer Segmentation**")
            try:
                segmentation_query = """
                SELECT 
                    CASE 
                        WHEN monthly_bill_amount >= 100 THEN 'Premium'
                        WHEN monthly_bill_amount >= 60 THEN 'Standard'
                        ELSE 'Basic'
                    END as segment,
                    COUNT(DISTINCT customer_id) as customer_count,
                    AVG(data_usage_gb) as avg_data_usage,
                    AVG(monthly_bill_amount) as avg_bill
                FROM customer_usage 
                WHERE usage_date >= DATEADD(month, -1, CURRENT_DATE())
                GROUP BY segment
                ORDER BY avg_bill DESC
                """
                
                seg_result = run_snowflake_query(segmentation_query)
                if seg_result:
                    seg_df = seg_result.to_pandas()
                    st.dataframe(seg_df, use_container_width=True)
                    
                    # Create segment visualization
                    fig = px.bar(seg_df, x='SEGMENT', y='CUSTOMER_COUNT',
                               title='Customer Segmentation',
                               color='AVG_BILL',
                               color_continuous_scale='Blues')
                    st.plotly_chart(fig, use_container_width=True)
                    
            except Exception as e:
                st.error(f"Error loading segmentation data: {str(e)}")
        
        with col2:
            st.markdown("#### 📱 **Device Usage Analysis**")
            try:
                device_query = """
                SELECT 
                    device_type,
                    COUNT(DISTINCT customer_id) as users,
                    AVG(data_usage_gb) as avg_data_usage,
                    AVG(voice_minutes) as avg_voice_minutes
                FROM customer_usage 
                WHERE usage_date >= DATEADD(month, -1, CURRENT_DATE())
                GROUP BY device_type
                ORDER BY users DESC
                """
                
                device_result = run_snowflake_query(device_query)
                if device_result:
                    device_df = device_result.to_pandas()
                    st.dataframe(device_df, use_container_width=True)
                    
                    # Create device pie chart
                    fig = px.pie(device_df, values='USERS', names='DEVICE_TYPE',
                               title='Device Usage Distribution')
                    st.plotly_chart(fig, use_container_width=True)
                    
            except Exception as e:
                st.error(f"Error loading device data: {str(e)}")

if __name__ == "__main__":
    main()

# Sample Customer Analytics Questions:
# - What is the average data usage by service plan?
# - Which customers have the highest monthly bills?
# - Show me usage patterns by device type
# - What's the revenue distribution across customer segments?
# - Which service plans have the highest customer satisfaction?
# - Identify customers who might be ready for plan upgrades