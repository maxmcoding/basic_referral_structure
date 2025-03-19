# Referral and Commission System SQL

## Overview
This project is a relational database schema designed for managing a referral and commission system. It includes entities for customers, referrers, referrals, commissions, payouts, reservations, and services.

## Features
- **Referral Tracking**: Links referrers with referred customers.
- **Commission Management**: Calculates and stores commissions earned by referrers.
- **Payout System**: Tracks referral payouts and statuses.
- **Coupons and Discounts**: Manages discount codes and their usage.
- **Reservation System**: Handles customer reservations and service usage.

## Database Schema
The database consists of the following tables:
- `customers`: Stores customer information.
- `referrers`: Holds data about referrers and their commissions.
- `referrals`: Links referrers to referred customers.
- `reservations`: Tracks service reservations by customers.
- `services`: Defines available services and pricing.
- `coupons`: Manages discount codes and their validity.
- `referral_commission`: Configures commission rules.
- `referral_payout`: Manages commission payments to referrers.
- `commission_statement`: Records commission transactions.

## Installation
1. Clone the repository:
   ```sh
   git clone https://github.com/your-username/referral-commission-system.git
   ```
2. Set up a PostgreSQL database instance.
3. Import the schema to your database.
4. Configure the application settings as needed.

## Usage
- Register referrers and customers.
- Track referrals and apply commissions based on reservations.
- Generate payout statements and manage payments.
- Apply discount codes to reservations.

## Contribution
Feel free to submit pull requests or open issues for feature requests and bug reports.

## License
This project is licensed under the MIT License.

