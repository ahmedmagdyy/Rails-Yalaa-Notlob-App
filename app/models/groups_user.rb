class GroupsUser < ApplicationRecord
  belongs_to :group , dependent: :destroy
  belongs_to :user , dependent: :destroy
end
