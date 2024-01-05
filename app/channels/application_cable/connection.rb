# frozen_string_literal: true

module ApplicationCable
  # The app defines no channels yet, but /cable is mounted by default. Without
  # this check any anonymous client could hold a socket open, and the first
  # channel added would inherit an unauthenticated connection. Identifying by
  # the Devise user also lets a channel scope its streams to current_user.
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = env["warden"]&.user || reject_unauthorized_connection
    end
  end
end
