import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donaid/Donor/DonorAlertDialog/DonorAlertDialogs.dart';
import 'package:donaid/Donor/campaign_donate_screen.dart';
import 'package:donaid/Models/Campaign.dart';
import 'package:donaid/Models/Organization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'DonorWidgets/donor_bottom_navigation_bar.dart';
import 'DonorWidgets/donor_drawer.dart';
import 'package:get/get.dart';


class CategoryCampaignsScreen extends StatefulWidget {
  final categoryName;
  const CategoryCampaignsScreen({Key? key, this.categoryName})
      : super(key: key);

  @override
  _CategoryCampaignsScreenState createState() =>
      _CategoryCampaignsScreenState();
}

class _CategoryCampaignsScreenState extends State<CategoryCampaignsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<Campaign> campaigns = [];
  List<Organization> organizations=[];
  var f = NumberFormat("###,##0.00", "en_US");

  @override
  void initState() {
    super.initState();
    _getCampaigns();
  }

  _refreshPage(){
    campaigns.clear();
    _getCampaigns();
    setState(() {

    });
  }

  _getCampaigns() async {
    var ret = await _firestore.collection('Campaigns')
        .where('category', isEqualTo: widget.categoryName)
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
          active: element.data()['active']
      );
      campaigns.add(campaign);
    }
    setState(() {});
    _getCampaignOrganizations();
  }

  _getCampaignOrganizations() async{
    for(var campaign in campaigns){
      var ret = await _firestore.collection('OrganizationUsers')
          .where('uid', isEqualTo: campaign.organizationID)
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

  _categoryCampaignsBody() {
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
                    if(organizations[index].country =='United States'){
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return (CampaignDonateScreen(campaigns[index]));
                      })).then((value) => _refreshPage());
                    }
                    else{
                      DonorAlertDialogs.paymentLinkPopUp(context, organizations[index], _auth.currentUser!.uid);
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

                const Divider()
              ],
            ),
          );
        })
    :  Center(child: Text('no_compaigns_in_this_category'.tr, style: TextStyle(fontSize: 18),));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //doubt
        title: Text('campaigns'.tr+' - ${widget.categoryName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      drawer: const DonorDrawer(),
      body: _categoryCampaignsBody(),
      bottomNavigationBar: DonorBottomNavigationBar(),
    );
  }
}
