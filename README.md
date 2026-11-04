# Wallet System API

Internal wallet transactional system built with **Ruby on Rails 8 (API-only)**.
Provides generic wallets for any entity (User, Team, Stock, …) with
ACID-compliant credit, debit, and transfer operations.

---

## Table of Contents

- [Requirements](#requirements)
- [Setup](#setup)
- [Authentication](#authentication)
- [API Endpoints](#api-endpoints)
- [Error Responses](#error-responses)
- [Design Decisions](#design-decisions)
- [Testing](#testing)
- [LatestStockPrice Library](#lateststockprice-library)
- [Known Limitations](#known-limitations)

---

## Requirements

- Ruby 3.3+
- Rails 8.1+
- PostgreSQL 14+
- (Optional) `RAPIDAPI_KEY` environment variable for the stock price library

---

## Setup

```bash
# Install dependencies
bundle install

# Create & migrate database
rails db:create db:migrate

# Seed demo data (creates demo users, team, stock, initial deposit)
rails db:seed

# Start the server
rails s