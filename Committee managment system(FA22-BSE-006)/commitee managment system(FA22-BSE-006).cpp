#include <iostream>
#include <string>
#include <cstdlib>
#include <ctime>
using namespace std;
class Member 
{
    int member_id;
    string name;
    int payment_status;

public:
    Member(int id, string n) 
	{
        member_id = id;
        name = n;
        payment_status = 0;
    }

    void make_payment() 
	{
        payment_status = 1;
    }

    int is_paid() const 
	{
        return payment_status;
    }

    int get_id() const 
	{
        return member_id;
    }

    string get_name() const 
	{
        return name;
    }

    void display() const 
	{
        string status = (payment_status == 1) ? "Paid" : "Unpaid";
        cout << "Member ID: "<< member_id << ", Name: " << name << ", Status: " << status << endl;
    }
};

class Committee 
{
    string committee_name;
    Member* members[5];
    int member_count;
public:
    Committee(string n)
    {
	 committee_name=n;
	 member_count=0;
}

    void add_member(int id, string name) 
	{
        if (member_count < 5) 
		{
            members[member_count] = new Member(id, name);
            cout << name << " added to the committee." << endl;
            member_count++;
        }
		 else 
		{
            cout << "Committee is full! Cannot add more members." << endl;
        }
    }

    void collect_payment(int member_id, int amount) 
	{
        if (amount != 1000) 
		{
            cout << "Payment must be exactly 1000. Payment not collected." << endl;
            return;
        }

        for (int i = 0; i < member_count; i++) 
		{
            if (members[i]->get_id() == member_id) 
			{
                members[i]->make_payment();
                cout << "Payment of 1000 collected from " << members[i]->get_name() << "." << endl;
                return;
            }
        }
        cout << "Member not found!" << endl;
    }

    void show_member_status() const 
	{
        cout << "Member Status in " << committee_name << ":" << endl;
        for (int i = 0; i < member_count; i++) 
		{
            members[i]->display();
        }
    }

    void conduct_lucky_draw() 
	{
        int paid_members_count = 0;
        Member* paid_members[5];

        for (int i = 0; i < member_count; i++) 
		{
            if (members[i]->is_paid() == 1) 
			{
                paid_members[paid_members_count] = members[i];
                paid_members_count++;
            }
        }

        if (paid_members_count == 0) 
		{
            cout << "No paid members. Lucky draw cannot be conducted." << endl;
        } 
		else 
		{
            srand(time(0));
            int winner_index = rand() % paid_members_count;
            cout << "Lucky Draw Winner: " << paid_members[winner_index]->get_name() << "!" << endl;
        }
    }

    ~Committee() 
	{
        for (int i = 0; i < member_count; i++) 
		{
            delete members[i];
        }
    }
};

int main() 
{
    Committee my_committee("Monthly Savings Committee");
    int choice;
    cout << "*****Welcome to Committee Management System*****" << endl;

    while (true) 
	{
        cout << endl;
        cout<<"======================================"<<endl;
        cout << "1. Add Member" << endl;
        cout << "2. Collect Payment" << endl;
        cout << "3. Show Member Status" << endl;
        cout << "4. Conduct Lucky Draw" << endl;
        cout << "5. Exit" << endl;
        cout<<"======================================"<<endl;
        cout << "Enter your choice: ";
        cin >> choice;
        
        switch (choice) 
		{
            case 1: 
			{
                int id;
                string name;
                cout << "Enter Member ID: ";
                cin >> id;
                cout << "Enter Member Name: ";
                cin >> name;
                my_committee.add_member(id, name);
                break;
            }
            case 2: 
			{
                int id, amount;
                cout << "Enter Member ID to collect payment: ";
                cin >> id;
                cout << "Enter payment amount (must be 1000): ";
                cin >> amount;
                my_committee.collect_payment(id, amount);
                break;
            }
            case 3:
                my_committee.show_member_status();
                break;
            case 4:
                my_committee.conduct_lucky_draw();
                break;
            case 5:
                cout << "*****Thanks for using Committee Management System*****" << endl;
                return 0;
            default:
                cout << "Invalid choice. Please try again." << endl;
        }
    }

    return 0;
}
