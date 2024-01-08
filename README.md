# Real-time Notis

This project constitutes a basic web application constructed utilizing Ruby on Rails 7.0 framework, leveraging PostgreSQL as its database management system.

Within this application, users can register by providing their phone numbers to receive SMS notifications based on specific triggers. Upon signup, users receive an initial SMS notification. Additionally, when users press two designated buttons on the homepage, the application triggers the sending of SMS messages containing different content. The integration of Twilio API facilitates the transmission of these SMS messages.

<img height="500" src="?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MDQ3MDQyNzUsIm5iZiI6MTcwNDcwMzk3NSwicGF0aCI6Ii8xMTk0MzI0ODcvMjk0ODQ5Nzg3LTk3MDI0NjMxLTI1NGItNGI4ZC04ZjcwLTcwOGYwNzY2MWIyOS5qcGVnP1gtQW16LUFsZ29yaXRobT1BV1M0LUhNQUMtU0hBMjU2JlgtQW16LUNyZWRlbnRpYWw9QUtJQVZDT0RZTFNBNTNQUUs0WkElMkYyMDI0MDEwOCUyRnVzLWVhc3QtMSUyRnMzJTJGYXdzNF9yZXF1ZXN0JlgtQW16LURhdGU9MjAyNDAxMDhUMDg1MjU1WiZYLUFtei1FeHBpcmVzPTMwMCZYLUFtei1TaWduYXR1cmU9N2Q1OTgwZjBiMDMyNWY5OTc2ZmQ1MTE3OWEwMWIwMDA0NWRiZmM1NzI2MjkzOGE3OGQzZTcwMWE1YmQ1NWU2YiZYLUFtei1TaWduZWRIZWFkZXJzPWhvc3QmYWN0b3JfaWQ9MCZrZXlfaWQ9MCZyZXBvX2lkPTAifQ.hShbD1YV2O-Tml1WuO2AZa11GU59MQ4vfUjZ69fhhZg" >

# Features

- devise gem for authentication with additional attribute name and phone number.
- Real-time sms notification to specific triggers. (signup, two buttons provided on home page)
- Twilio integration for sms sending service.

# Build With

- Framework: Ruby on Rails 7.0
- Database: PostgreSQL
- API: Twilio (gem twilio-ruby)

# Getting Started

## Prerequisites


  ```bash
  brew install postgresql
  \curl -sSL https://get.rvm.io | bash -s stable
  rvm i 3.2.2
  ```

## Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Chsaleem31/real-time-notis.git
   ```

2. **Initialize the Database**:
   - Before starting the application for the first time, ensure that the database is set up correctly.
   ```bash
   rails db:create db:migrate
   ```
   - Now run the application with
   ```bash
   rails s
   visit the url localhost:3000
   ```

