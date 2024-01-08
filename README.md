# Real-time Notis

This project constitutes a basic web application constructed utilizing Ruby on Rails 7.0 framework, leveraging PostgreSQL as its database management system.

Within this application, users can register by providing their phone numbers to receive SMS notifications based on specific triggers. Upon signup, users receive an initial SMS notification. Additionally, when users press two designated buttons on the homepage, the application triggers the sending of SMS messages containing different content. The integration of Twilio API facilitates the transmission of these SMS messages.

**Demo**

[https://www.loom.com/share/fd5f927058f348c481ce9dc8a2872045]

<img height="500" src="https://github.com/Chsaleem31/real-time-notis/assets/119432487/df88d5cd-afc2-4d9b-9cfd-f80b9219024b" >

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

2.  **Edit credentials file**:

```bash
EDITOR=vim rails credentials:edit
```
```
twilio:
   account_sid: your account sid
   auth_token: auth token
```

3. **Initialize the Database**:
   - Before starting the application for the first time, ensure that the database is set up correctly.
   ```bash
   bundle install
   rails db:create db:migrate
   ```
   - Now run the application with
   ```bash
   rails s
   visit the url localhost:3000
   ```
