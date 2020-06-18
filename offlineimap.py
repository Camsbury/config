import os
import subprocess

def get_password(acct):
  acct = os.path.basename(acct)
  user_name = os.getenv('USER')
  path = "/home/%s/.offlineimap/passwords/%s.gpg" % (user_name, acct)
  args = ["gpg", "--use-agent", "--quiet", "--batch", "-d", path]
  try:
    return subprocess.check_output(args).strip()
  except subprocess.CalledProcessError:
    return ""

def folder_filter(folder_name):
  return folder_name not in [
    '[Gmail]/All Mail',
    '[Gmail]/Important',
    '[Gmail]/Trash',
    '[Gmail]/Archive',
  ]

names = {
  'Applications': 'applications',
  'Business Subscription': 'business_subscription',
  'Citibike': 'citibike',
  'Genetics': 'genetics',
  'INBOX': 'inbox',
  'Kingsbury Tour': 'kingsbury_tour',
  'Little Grammercy': 'little_grammercy',
  'Personal': 'personal',
  'Pics': 'pics',
  'Races': 'races',
  'Receipts': 'receipts',
  'Room': 'room',
  'Taxes': 'taxes',
  'TractManager': 'tract_manager',
  'Travel': 'travel',
  'Urbint': 'urbint',
  'Waterside': 'waterside',
  'Work': 'work',
  '[Gmail]/Drafts': 'drafts',
  '[Gmail]/Sent Mail': 'sent',
  '[Gmail]/Spam': 'spam',
  '[Gmail]/Starred': 'starred',
  '[Gmail]/Trash': 'trash',
}
reverse_names = {value:key for key, value in names.items()}

def name_trans(folder_name):
  if folder_name in names:
    return names[folder_name]
  return folder_name

def reverse_name_trans(folder_name):
  if folder_name in reverse_names:
    return reverse_names[folder_name]
  return folder_name

