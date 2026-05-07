<!-- markdownlint-disable-file -->
# Task Research: Taipei Urban Rat Distribution Dashboard

Research for building a web dashboard to analyze urban rat distribution and prevention strategies in Taipei city, based on the provided article highlighting the lack of scientific data since 2015.

## Task Implementation Requests

* Research current rat infestation status in Taipei
* Identify data sources for rat distribution mapping
* Analyze prevention strategies and policies
* Recommend technologies for web dashboard development
* Propose dashboard features for data visualization and analysis

## Scope and Success Criteria

* Scope: Taipei city urban areas, rat population data, prevention methods, web technologies for dashboard
* Assumptions: User has web development skills, access to data sources, focus on data-driven prevention
* Success Criteria:
  * Comprehensive overview of Taipei's rat problem
  * Identified data sources and gaps
  * Recommended prevention strategies
  * Technical architecture for dashboard
  * Actionable implementation plan

## Outline

* Current Situation in Taipei
* Historical Data and Surveys
* Prevention Strategies
* Data Sources for Dashboard
* Dashboard Technologies and Features
* Implementation Recommendations

## Potential Next Research

* Detailed analysis of rat ecology in urban Taipei
  * Reasoning: Understanding rat behavior and habitats for better prevention
  * Reference: Scientific literature on urban rodents
* Integration with citizen reporting systems
  * Reasoning: Supplement official data with community input
  * Reference: Similar initiatives in other cities
* Environmental factors affecting rat populations
  * Reasoning: Climate, waste management, urban planning impacts
  * Reference: Taipei environmental reports
* Implementation of K-Dense scientific agent skills for population modeling
  * Reasoning: Use GeoMaster, PyMC, aeon, scikit-learn to enhance dashboard capabilities
  * Reference: .copilot-tracking/research/2026-05-06/urban-rats-prevention-skills-research.md
* Custom agent skill development for rodent population prediction
  * Reasoning: Build specialized skills for Taipei-specific rat ecology data
  * Reference: K-Dense-AI/scientific-agent-skills repository framework

## Research Executed

### File Analysis

* Untitled-1: Contains Supabase credentials and API endpoints for reports_v table
  * Lines 1-4: Azure and Supabase configuration
  * Lines 6-9: API query examples for leftover type reports

### Code Search Results

* supabase-client.js: Supabase client configuration
* config.js: Application configuration

### External Research

* Taipei rat infestation article: Highlights 12-year gap in scientific surveys since 2015
  * Key points: No density data, no population studies, reliance on complaint calls
  * Source: Local news article (Chinese)

### Project Conventions

* Technologies: JavaScript, Supabase for backend, static web app
* Instructions followed: Web dashboard development, data visualization

## Key Discoveries

### Project Structure

* Public folder with HTML files, JS config, Supabase client
* Supabase migrations for database schema

### Implementation Patterns

* API queries for reports data
* Static web app deployment via Azure

### Complete Examples

```javascript
// From supabase-client.js
const supabaseUrl = 'https://hfwqxazrcehwqnmktead.supabase.co';
const supabaseKey = 'sb_publishable_Ff8jQgOMLX5bTqjJ1qENmg_CoB0RHck';
```

### API and Schema Documentation

* Supabase REST API for reports_v table
* Query parameters: type=leftover, limit=3

### Configuration Examples

```json
// staticwebapp.config.json
{
  "routes": [],
  "navigationFallback": {
    "rewrite": "/index.html"
  }
}
```

## Technical Scenarios

### Rat Distribution Mapping Dashboard

**Requirements:**

* Visualize rat reports on Taipei map
* Show temporal trends
* Identify hotspots
* Prevention recommendations

**Preferred Approach:**

* Use Leaflet or Mapbox for mapping
* Supabase for data storage
* Chart.js or D3.js for visualizations
* React or vanilla JS for frontend

```text
Dashboard Structure:
├── Map View (rat locations)
├── Charts (trends, types)
├── Reports Table
└── Prevention Guidelines
```

**Implementation Details:**

* Fetch data from Supabase API
* Geocode addresses to coordinates
* Cluster markers for density visualization
* Filter by date, type, district

#### Considered Alternatives

* GIS software: Too complex for web dashboard
* Static reports: Lacks interactivity
* Government APIs: Limited availability

### Enhanced Urban Rat Population Modeling with K-Dense Scientific Skills

**Requirements:**

* Scientific population dynamics modeling
* Predictive forecasting of rat population trends
* Spatial habitat analysis and risk mapping
* Bayesian uncertainty quantification for predictions

**Preferred Approach:**

* Integrate K-Dense Scientific Agent Skills for data-driven analysis:
  * **GeoMaster**: Spatial analysis of urban environments to identify rat habitats and track population spread using satellite and urban planning data
  * **PyMC**: Bayesian modeling of rat population dynamics with uncertainty quantification
  * **aeon**: Time series forecasting of population trends and anomaly detection
  * **scikit-learn**: Machine learning models for infestation risk prediction based on environmental factors

```text
Enhanced Dashboard Architecture:
├── Data Layer (Supabase)
│   ├── Reports (citizen submissions)
│   ├── Environmental factors (temp, humidity, food sources)
│   └── Urban planning data (parks, waste sites, buildings)
├── AI Agent Skills Layer
│   ├── GeoMaster (habitat mapping)
│   ├── PyMC (population modeling)
│   ├── aeon (trend forecasting)
│   └── scikit-learn (risk prediction)
├── Analysis & Insights
│   ├── Population forecasts
│   ├── Hotspot predictions
│   ├── Habitat vulnerability maps
│   └── Prevention effectiveness metrics
└── Visualization Layer
    ├── Interactive map (current + predicted hotspots)
    ├── Population trend charts
    ├── Risk heatmaps
    └── Scenario analysis dashboards
```

**Implementation Details:**

* Connect Supabase data to PyMC for Bayesian population modeling
* Use GeoMaster for satellite imagery analysis of green spaces and potential habitats
* Apply aeon time series algorithms to forecast population growth patterns
* Deploy scikit-learn models to predict high-risk areas based on environmental features
* Visualize predictions and uncertainty bounds in interactive maps and charts
* Enable scenario analysis (e.g., "what if rat control measures increase by 20%?")

**Integration Strategy:**

1. Start with basic dashboards (reports visualization, hotspot mapping)
2. Layer in scikit-learn predictive models for risk scoring
3. Add aeon time series forecasting for trend prediction
4. Implement PyMC Bayesian models for population dynamics
5. Integrate GeoMaster for spatial habitat analysis (requires satellite data access)

**Expected Outcomes:**

* Replace 12-year data gap with AI-driven population estimates
* Provide scientific foundation for prevention policy recommendations
* Enable proactive instead of reactive rat control measures
* Support "科學" (scientific) approach mentioned in the original article

#### Considered Alternatives for Skills Integration

* Manual statistical analysis: Less sophisticated, slower, limited to past data
* Simple ML models only: No uncertainty quantification, weaker population dynamics
* No scientific modeling: Returns to current approach of only using complaint data

## Selected Approach

**Integrated Solution: AI-Enhanced Rat Distribution Dashboard for Taipei**

The dashboard combines your existing Supabase infrastructure with K-Dense Scientific Agent Skills to provide data-driven rat prevention capabilities:

### Technology Stack

```
Frontend: Vanilla JS + Leaflet/Mapbox (existing setup)
Backend: Supabase + Python microservices for AI agents
AI Skills: GeoMaster (spatial), PyMC (Bayesian modeling), aeon (forecasting), scikit-learn (prediction)
Deployment: Azure Static Web Apps (existing)
```

### Core Features

1. **Real-time Reporting Dashboard** (Phase 1 - Existing)
   - Map visualization of citizen reports
   - Report filtering and hotspot identification
   - Basic statistics and trends

2. **Predictive Analytics** (Phase 2 - AI Skills Layer)
   - scikit-learn: Risk scoring for districts based on environmental factors
   - aeon: Population trend forecasting with 1-3 month predictions
   - PyMC: Bayesian population dynamics models with uncertainty bounds

3. **Spatial Intelligence** (Phase 3 - Advanced)
   - GeoMaster: Habitat suitability mapping using satellite imagery
   - Integration of urban planning data (parks, waste sites, building density)
   - Vulnerability assessment for different city districts

4. **Prevention Strategy Support**
   - Scenario modeling ("if control intensity increases by X%")
   - Evidence-based recommendations for resource allocation
   - Progress tracking against population targets

### Why This Approach

* **Addresses Taipei's Gap**: Replaces missing scientific surveys with AI-driven population estimates
* **Aligns with Article's Call**: Implements the "科學" (scientific) and "專業" (professional) approach requested
* **Leverages Existing Assets**: Uses current Supabase setup and Azure deployment
* **Phased Implementation**: Starts simple, adds sophistication incrementally
* **Actionable Insights**: Provides city planners with evidence for policy decisions

### Rationale Over Alternatives

- **vs. Manual Analysis**: Scientific algorithms provide superior pattern recognition and forecasting
- **vs. Simple Dashboards**: Bayesian and ML models enable uncertainty quantification and scenario testing
- **vs. Government-Only Data**: Combines citizen reports with environmental and spatial analysis for comprehensive view

### Success Metrics

- Population estimates align with periodic validation surveys
- Hotspot predictions match actual reports 2-4 weeks in advance
- Risk model achieves 75%+ accuracy on held-out test data
- Policy makers adopt recommendations based on dashboard insights

