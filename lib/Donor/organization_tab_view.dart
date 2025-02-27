import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donaid/Donor/DonorAlertDialog/DonorAlertDialogs.dart';
import 'package:donaid/Models/Beneficiary.dart';
import 'package:donaid/Models/Campaign.dart';
import 'package:donaid/Models/Organization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'DonorWidgets/donor_bottom_navigation_bar.dart';
import 'DonorWidgets/donor_drawer.dart';
import 'beneficiary_donate_screen.dart';
import 'campaign_donate_screen.dart';
import 'package:get/get.dart';


class OrganizationTabViewScreen extends StatefulWidget {
  final Organization organization;
  const OrganizationTabViewScreen({Key? key, required this.organization}) : super(key: key);

  @override
  _OrganizationTabViewScreenState createState() => _OrganizationTabViewScreenState();
}

class _OrganizationTabViewScreenState extends State<OrganizationTabViewScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<Beneficiary> beneficiaries=[];
  List<Campaign> campaigns=[];
  var f = NumberFormat("###,##0.00", "en_US");

  @override
  void initState() {
    super.initState();
    _getOrganizationCampaigns();
    _getOrganizationBeneficiaries();
  }
  
  _refreshPage(){
    beneficiaries.clear();
    campaigns.clear();
    _getOrganizationCampaigns();
    _getOrganizationBeneficiaries();
  }
  
  _getOrganizationBeneficiaries() async {
    //Get all beneficiaries created by the chosen organization
    var ret = await _firestore.collection('Beneficiaries')
        .where('organizationID', isEqualTo: widget.organization.uid)
        .where('active',isEqualTo: true)
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
          active: element.data()['active'],
      );
      beneficiaries.add(beneficiary);
    }
    setState(() {});
  }

  _getOrganizationCampaigns()async{
    //Get all campaigns created by the chosen organization
    var ret = await _firestore.collection('Campaigns')
        .where('organizationID',isEqualTo: widget.organization.uid)
        .where('active', isEqualTo: true)
        .where('endDate',isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('endDate',descending: false)
        .get();

    for (var element in ret.docs) {
      Campaign campaign = Campaign(
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
      );
      campaigns.add(campaign);
    }
    setState(() {});
  }

  _organizationCampaignsBody(){
    //Show all the active campaigns for the chosen organization
    return campaigns.isNotEmpty
    ? ListView.builder(
        itemCount: campaigns.length,
        shrinkWrap: true,
        itemBuilder: (context, int index) {
          return Card(
            child: Column(
              children: [
                ListTile(
                  onTap: () {
                    if(widget.organization.country =='United States'){
                      //If organization is from US, navigate to the campaign donate screen
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return (CampaignDonateScreen(campaigns[index]));
                      })).then((value) => _refreshPage());
                    }
                    else{
                      //If the organization is not from US, create payment gateway link popup

                      //The charity object is used to create a payment gateway visit record if the user
                      //clicks on the payment gatgeway link
                      Map<String, dynamic> charity = {
                        'charityID':campaigns[index].id,
                        'charityType':'Campaign',
                        'charityTitle':campaigns[index].title
                      };
                      DonorAlertDialogs.paymentLinkPopUp(context, widget.organization, _auth.currentUser!.uid, charity);
                    }
                  },
                  title: Text(campaigns[index].title),
                  subtitle: Text(campaigns[index].description),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('\$'+f.format(campaigns[index].amountRaised),
                            textAlign: TextAlign.left,
                            style: const TextStyle(color: Colors.black, fontSize: 15)),
                        Text(
                          '\$'+f.format(campaigns[index].goalAmount),
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
                          value: (campaigns[index].amountRaised/campaigns[index].goalAmount),
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height:10)
              ],
            ),
          );
        })
        //doubt
    :  Center(child: Text('this_organization_does_not_have_any_active_campaigns_at_this_time'.tr, style: TextStyle(fontSize: 18),));
  }

  _organizationBeneficiariesBody(){
    //Display all active beneficiaries for the chosen organization
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
                    if(widget.organization.country =='United States'){
                      //If the organization is from US, navigate to the beneficiary donate screen
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return (BeneficiaryDonateScreen(beneficiaries[index]));
                      })).then((value) => _refreshPage());
                    }
                    else{
                      //If the organization is foreign, create payment link popup

                      //charity object is used to create payment gateway visit record if the user
                      // clicks the payment gateway link
                      Map<String, dynamic> charity = {
                        'charityID':beneficiaries[index].id,
                        'charityType':'Beneficiary',
                        'charityTitle':beneficiaries[index].name
                      };
                      DonorAlertDialogs.paymentLinkPopUp(context, widget.organization, _auth.currentUser!.uid, charity);
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
                SizedBox(height:10)
              ],
            ),
          );
        })
        //doubt
    : Center(child: Text('this_organization_does_not_have_any_active_beneficiaries_at_this_time'.tr, style: TextStyle(fontSize: 18),));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom:  TabBar(tabs: [Tab(text: '_campaigns'.tr,), Tab(text: 'beneficiaries'.tr,)],),
          title: Text(widget.organization.organizationName),
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
            _organizationCampaignsBody(),
            _organizationBeneficiariesBody()
          ],
        ),
        bottomNavigationBar:  DonorBottomNavigationBar(),
      ),
    );
  }
}
