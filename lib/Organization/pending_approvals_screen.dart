import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donaid/Models/UrgentCase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'OrganizationWidget/organization_bottom_navigation.dart';
import 'OrganizationWidget/organization_drawer.dart';
import 'organization_urgentcase_full.dart';

class PendingApprovals extends StatefulWidget {
  const PendingApprovals({Key? key}) : super(key: key);

  @override
  _PendingApprovalsState createState() => _PendingApprovalsState();
}

class _PendingApprovalsState extends State<PendingApprovals> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<UrgentCase> urgentCases = [];

  @override
  void initState() {
    super.initState();
    _getUrgentCases();
  }

  _refreshPage() async{
    urgentCases.clear();
    _getUrgentCases();
    setState(() {

    });
  }

  _getUrgentCases() async {
    var ret = await _firestore.collection('UrgentCases')
        .where('organizationID', isEqualTo: _auth.currentUser?.uid)
        .where('endDate',isGreaterThanOrEqualTo: Timestamp.now())
        .where('active', isEqualTo: true)
        .where('approved',isEqualTo: false)
        .orderBy('endDate', descending: false)
        .get();

    for (var element in ret.docs) {
      UrgentCase urgentCase = UrgentCase(
          title: element.data()['title'],
          description: element.data()['description'],
          goalAmount: element.data()['goalAmount'].toDouble(),
          amountRaised: element.data()['amountRaised'].toDouble(),
          category: element.data()['category'],
          endDate: element.data()['endDate'],
          dateCreated: element.data()['dateCreated'],
          id: element.data()['id'],
          organizationID: element.data()['organizationID'],
          active: element.data()['active'],
          approved: element.data()['approved']
      );
      urgentCases.add(urgentCase);
    }
    setState(() {});
  }


  _urgentCasesBody() {
    return ListView.builder(
        itemCount: urgentCases.length,
        shrinkWrap: true,
        itemBuilder: (context, int index) {
          return Card(
            child: Column(
              children: [
                ListTile(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return (OrganizationUrgentCaseFullScreen(urgentCases[index]));
                    })).then((value) => _refreshPage());
                  },
                  title: Text(urgentCases[index].title),
                  subtitle: Text(urgentCases[index].description),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('\$${(urgentCases[index].amountRaised.toStringAsFixed(2))}',
                      textAlign: TextAlign.left,
                      style: const TextStyle(color: Colors.black, fontSize: 15)),
                  Text(
                    '\$${urgentCases[index].goalAmount.toStringAsFixed(2)}',
                    textAlign: TextAlign.start,
                    style: const TextStyle(color: Colors.black, fontSize: 15),
                  ),
                ]),
                LinearProgressIndicator(
                  backgroundColor: Colors.grey,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor),
                  value: (urgentCases[index].amountRaised/urgentCases[index].goalAmount),
                  minHeight: 10,
                ),
                const Divider()
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      drawer: const OrganizationDrawer(),
      body: _urgentCasesBody(),
      bottomNavigationBar: const OrganizationBottomNavigation(),
    );
  }
}
