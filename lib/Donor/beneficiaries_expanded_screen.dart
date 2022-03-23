import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donaid/Donor/beneficiary_donate_screen.dart';
import 'package:donaid/Models/Beneficiary.dart';
import 'package:donaid/Models/Organization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../Models/Adoption.dart';
import 'DonorWidgets/donor_bottom_navigation_bar.dart';
import 'DonorWidgets/donor_drawer.dart';
import 'adoption_details_screen.dart';
import 'beneficiary_donate_screen.dart';

class BeneficiaryExpandedScreen extends StatefulWidget {
  static const id = 'beneficaries_expanded_screen';
  const BeneficiaryExpandedScreen({Key? key})
      : super(key: key);

  @override
  _BeneficiaryExpandedScreenState createState() =>
      _BeneficiaryExpandedScreenState();
}

class _BeneficiaryExpandedScreenState extends State<BeneficiaryExpandedScreen> {
  final _firestore = FirebaseFirestore.instance;
  List<Beneficiary> beneficiaries = [];
  List<Organization> organizations=[];
  var f = NumberFormat("###,##0.00", "en_US");
  List<Adoption> adoptions = [];


  @override
  void initState() {
    super.initState();
    _getBeneficiaries();
    _getAdoptions();
  }
  
  _refreshPage(){
    beneficiaries.clear();
    adoptions.clear();
    _getBeneficiaries();
    _getAdoptions();
    setState(() {
      
    });
  }


  _getBeneficiaries() async {
    var ret = await _firestore.collection('Beneficiaries')
        .where('active', isEqualTo: true)
        .where('endDate',isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('endDate',descending: false)
        .get();

    for (var element in ret.docs) {
      Beneficiary beneficiary = Beneficiary(
          name: element.data()['name'],
          biography: element.data()['biography'],
          goalAmount: element.data()['goalAmount'].toDouble(),
          amountRaised: element.data()['amountRaised'].toDouble(),
          category: element.data()['category'],
          endDate: element.data()['endDate'],
          dateCreated: element.data()['dateCreated'],
          id: element.data()['id'],
          organizationID: element.data()['organizationID'],
          active: element.data()['active']
      );
      beneficiaries.add(beneficiary);
    }
    setState(() {});
    _getBeneficiaryOrganizations();
  }
  _getAdoptions() async {
    try{
      var ret = await _firestore
          .collection('Adoptions')
          .where('active', isEqualTo: true)
          .get();

      for (var element in ret.docs) {
        Adoption adoption = Adoption(
          name: element.data()['name'],
          biography: element.data()['biography'],
          goalAmount: element.data()['goalAmount'].toDouble(),
          amountRaised: element.data()['amountRaised'].toDouble(),
          category: element.data()['category'],
          dateCreated: element.data()['dateCreated'],
          id: element.data()['id'],
          organizationID: element.data()['organizationID'],
          active: element.data()['active'],
        );
        adoptions.add(adoption);
      }
    }
    catch(e){
      print(e);
    }

    setState(() {});
  }
  _getBeneficiaryOrganizations() async{
    for(var beneficiary in beneficiaries){
      var ret = await _firestore.collection('OrganizationUsers')
          .where('uid', isEqualTo: beneficiary.organizationID)
          .get();

      for(var element in ret.docs){
        Organization organization = Organization(
          organizationName: element.data()['organizationName'],
          uid: element.data()['uid'],
          organizationDescription: element.data()['organizationDescription'],
          country: element.data()['country'],
          gatewayLink: element.data()['gatewayLink'],
        );
        organizations.add(organization);
      }
    }
  }

  _paymentLinkPopUp(Organization organization){
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Center(
              child: Text('Detour!'),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32.0),
            ),
            content: Linkify(
              onOpen: (link) async {
                if (await canLaunch(link.url)) {
                  await launch(link.url);
                } else {
                  throw 'Could not launch $link';
                }
              },
              text: 'The organization that created this charity is not based in the United States. Due to this, we cannot process your payment.'
                  ' A link to the organization\'s payment gateway is below.\n\n ${organization.gatewayLink}',
              linkStyle: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              textAlign: TextAlign.center,
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ),
            ],
          );
        });
  }
  _beneficiariesBody() {
    return beneficiaries.isNotEmpty
    ? ListView.builder(
        itemCount: beneficiaries.length,
        shrinkWrap: true,
        itemBuilder: (context, int index) {
          return Card(
            child: Column(
              children: [
                ListTile(
                  onTap: () {
                    if(organizations[index].country =='United States'){
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return (BeneficiaryDonateScreen(beneficiaries[index]));
                      })).then((value) => _refreshPage());
                    }
                    else{
                      _paymentLinkPopUp(organizations[index]);
                    }
                  },
                  title: Text(beneficiaries[index].name),
                  subtitle: Text(beneficiaries[index].biography),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('\$'+f.format(beneficiaries[index].amountRaised),
                            textAlign: TextAlign.left,
                            style: const TextStyle(color: Colors.black, fontSize: 15)),
                        Text(
                          '\$'+f.format(beneficiaries[index].goalAmount),
                          textAlign: TextAlign.start,
                          style: const TextStyle(color: Colors.black, fontSize: 15),
                        ),
                      ]),
                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.grey,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.green),
                          value: (beneficiaries[index].amountRaised/beneficiaries[index].goalAmount),
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider()
              ],
            ),
          );
        })
    : const Center(child: Text('No active beneficiaries to show.', style: TextStyle(fontSize: 18),));
  }
  _adoptionsBody() {
    return RefreshIndicator(
      onRefresh: ()async{
        _refreshPage();
      },
      child: adoptions.isNotEmpty
          ? ListView.builder(
          itemCount: adoptions.length,
          shrinkWrap: true,
          itemBuilder: (context, int index) {
            return Card(
              child: Column(
                children: [
                  ListTile(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return (AdoptionDetailsScreen(adoptions[index]));
                      })).then((value) => _refreshPage());
                    },
                    title: Text(adoptions[index].name),
                    subtitle: Text(adoptions[index].biography),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('\$'+f.format(adoptions[index].amountRaised),
                              textAlign: TextAlign.left,
                              style: const TextStyle(color: Colors.black, fontSize: 15)),
                          Text(
                            '\$'+f.format(adoptions[index].goalAmount),
                            textAlign: TextAlign.start,
                            style: const TextStyle(color: Colors.black, fontSize: 15),
                          ),
                        ]),
                        ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.grey,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.green),
                            value: (adoptions[index].amountRaised/adoptions[index].goalAmount),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider()
                ],
              ),
            );
          })
          : const Center(child: Text('No active adoptions to show.', style: TextStyle(fontSize: 18),)),
    );
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(tabs: [Tab(text: 'Beneficiaries',), Tab(text: 'Adoptions',)],),
          title: const Text('Beneficiaries'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        drawer: const DonorDrawer(),
        body: TabBarView(
          children: [
            _beneficiariesBody(),
            _adoptionsBody()
          ],
        ),
        bottomNavigationBar:   DonorBottomNavigationBar(),
      ),
    );
  }
}
