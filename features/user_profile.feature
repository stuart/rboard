Feature: User Profile
  In order to change my details
  As a user
  I want to be able to edit my profile

  Background:
    Given there is the usual setup
    And I am on the homepage

  Scenario: Editing profile
    Given I am logged in as "registered_user"
    When I follow "Edit Profile"
    And I fill in "Display Name" with "Bobby"
    And I fill in "Signature" with "I am Bobby Brown, and I'm going down."
    And I select "(GMT+08:00) Perth" from "Time Zone"
    And I press "Update"
    Then I should see "The profile was updated"
    And I should see "Bobby"
    And I should see "I am Bobby Brown, and I'm going down."