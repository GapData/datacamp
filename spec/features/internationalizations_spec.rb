require 'spec_helper'

describe 'Internationalizations' do
  it 'user is able to change site language' do
    visit root_path(locale: :en)

    page.should have_content 'Login'

    click_link 'Slovensky'
    page.should have_content 'Prihlásenie'

    click_link 'English'
    page.should have_content 'Login'
  end
end