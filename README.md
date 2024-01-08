# Real-time Notis

This project constitutes a basic web application constructed utilizing Ruby on Rails 7.0 framework, leveraging PostgreSQL as its database management system.

Within this application, users can register by providing their phone numbers to receive SMS notifications based on specific triggers. Upon signup, users receive an initial SMS notification. Additionally, when users press two designated buttons on the homepage, the application triggers the sending of SMS messages containing different content. The integration of Twilio API facilitates the transmission of these SMS messages.

<img height="500" src="https://private-user-images.githubusercontent.com/119432487/294849787-97024631-254b-4b8d-8f70-708f07661b29.jpeg" >

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

