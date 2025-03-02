import 'dart:io';

List<Map<String, String>> contacts = [];

void main() {
  while (true) {
    print('\nContact Manager');
    print('1. Add Contact');
    print('2. View Contacts');
    print('3. Update Contact');
    print('4. Delete Contact');
    print('5. Exit');
    stdout.write('Choose an option: ');

    String? choice = stdin.readLineSync();
    if (choice == '5') break;

    if (choice == '1') addContact();
    else if (choice == '2') viewContacts();
    else if (choice == '3') updateContact();
    else if (choice == '4') deleteContact();
    else print('Invalid option. Try again.');
  }
  print('Exiting...');
}

void addContact() {
  stdout.write('Enter name: ');
  String? name = stdin.readLineSync();
  stdout.write('Enter phone: ');
  String? phone = stdin.readLineSync();
  stdout.write('Enter email: ');
  String? email = stdin.readLineSync();

  if (name == null || phone == null || email == null || name.isEmpty || phone.isEmpty || email.isEmpty) {
    print('All fields are required.');
    return;
  }

  contacts.add({'name': name, 'phone': phone, 'email': email});
  print('Contact added!');
}

void viewContacts() {
  if (contacts.isEmpty) {
    print('No contacts available.');
    return;
  }
  for (var contact in contacts) {
    print('Name: ${contact['name']}, Phone: ${contact['phone']}, Email: ${contact['email']}');
  }
}

void updateContact() {
  stdout.write('Enter name to update: ');
  String? name = stdin.readLineSync();

  for (var contact in contacts) {
    if (contact['name'] == name) {
      stdout.write('New phone (Enter to skip): ');
      String? phone = stdin.readLineSync();
      if (phone != null && phone.isNotEmpty) contact['phone'] = phone;

      stdout.write('New email (Enter to skip): ');
      String? email = stdin.readLineSync();
      if (email != null && email.isNotEmpty) contact['email'] = email;

      print('Contact updated!');
      return;
    }
  }
  print('Contact not found.');
}

void deleteContact() {
  stdout.write('Enter name to delete: ');
  String? name = stdin.readLineSync();
  contacts.removeWhere((contact) => contact['name'] == name);
  print('Contact deleted if it existed.');
}
