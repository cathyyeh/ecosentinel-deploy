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

