# for this feature to run you need to have a table 'testing' in your 'data' database for the testing environment. Please run db/data/ds_testing.sql

Feature: Dataset management and display

  Background:
    And a published dataset "testing"

  Scenario: A dataset record that is published should be shown to all users
    And a published record exists for dataset "testing"
    When I display records for dataset "testing"
    Then I should see "some content"
    
  
  Scenario: A dataset record that is not published should not be shown to all users
    And an unpublished record exists for dataset "testing"
    When I display records for dataset "testing"
    Then I should not see "some content"
    
  Scenario: A dataset record that is not published should not be shown to all users even when they are guessing urls
    And an unpublished record exists for dataset "testing"
    When I display page 1 of sorted records for dataset "testing"
    Then I should not see "some content"
  
  Scenario: A dataset record that is not published should be shown to admin user
    And I am a new, authenticated user "test" with password "password"
    And an unpublished record exists for dataset "testing"
    When I display records for dataset "testing"
    Then I should see "some content"