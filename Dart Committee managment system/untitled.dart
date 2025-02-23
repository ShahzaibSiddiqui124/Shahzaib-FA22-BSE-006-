import 'dart:io';
import 'dart:math';

class Member {
  int memberId;
  String name;
  bool paymentStatus;

  Member(this.memberId, this.name) : paymentStatus = false;

  void makePayment() {
    paymentStatus = true;
  }

  bool isPaid() {
    return paymentStatus;
  }

  void display() {
    String status = paymentStatus ? "Paid" : "Unpaid";
    print("Member ID: $memberId, Name: $name, Status: $status");
  }
}

class Committee {
  String committeeName;
  List<Member> members = [];
  final int maxMembers = 5;

  Committee(this.committeeName);

  void addMember(int id, String name) {
    if (members.length < maxMembers) {
      members.add(Member(id, name));
      print("$name added to the committee.");
    } else {
      print("Committee is full! Cannot add more members.");
    }
  }

  void collectPayment(int memberId, int amount) {
    if (amount != 1000) {
      print("Payment must be exactly 1000. Payment not collected.");
      return;
    }

    for (var member in members) {
      if (member.memberId == memberId) {
        member.makePayment();
        print("Payment of 1000 collected from ${member.name}.");
        return;
      }
    }
    print("Member not found!");
  }

  void showMemberStatus() {
    print("Member Status in $committeeName:");
    for (var member in members) {
      member.display();
    }
  }

  void conductLuckyDraw() {
    var paidMembers = members.where((m) => m.isPaid()).toList();
    if (paidMembers.isEmpty) {
      print("No paid members. Lucky draw cannot be conducted.");
    } else {
      var random = Random();
      var winner = paidMembers[random.nextInt(paidMembers.length)];
      print("Lucky Draw Winner: ${winner.name}!");
    }
  }
}

void main() {
  var myCommittee = Committee("Monthly Savings Committee");
  while (true) {
    print("\n======================================");
    print("1. Add Member");
    print("2. Collect Payment");
    print("3. Show Member Status");
    print("4. Conduct Lucky Draw");
    print("5. Exit");
    print("======================================");
    stdout.write("Enter your choice: ");
    var choice = int.tryParse(stdin.readLineSync()!);

    switch (choice) {
      case 1:
        stdout.write("Enter Member ID: ");
        int id = int.parse(stdin.readLineSync()!);
        stdout.write("Enter Member Name: ");
        String name = stdin.readLineSync()!;
        myCommittee.addMember(id, name);
        break;
      case 2:
        stdout.write("Enter Member ID to collect payment: ");
        int id = int.parse(stdin.readLineSync()!);
        stdout.write("Enter payment amount (must be 1000): ");
        int amount = int.parse(stdin.readLineSync()!);
        myCommittee.collectPayment(id, amount);
        break;
      case 3:
        myCommittee.showMemberStatus();
        break;
      case 4:
        myCommittee.conductLuckyDraw();
        break;
      case 5:
        print("*****Thanks for using Committee Management System*****");
        return;
      default:
        print("Invalid choice. Please try again.");
    }
  }
}
