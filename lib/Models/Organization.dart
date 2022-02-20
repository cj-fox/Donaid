class Organization {
  String? organizationEmail;
  String organizationName;
  String? phoneNumber;
  String uid;
  String? organizationDescription;
  String? country;
  String? gatewayLink;

  Organization({
    this.organizationEmail,
    required this.organizationName,
    this.phoneNumber,
    required this.uid,
    this.organizationDescription,
    this.country,
    this.gatewayLink
  });
  Organization.c1()
      :organizationEmail="",
        organizationName="",
        phoneNumber="",
        uid="",
        organizationDescription="",
        country="",
        gatewayLink=""
  ;
}