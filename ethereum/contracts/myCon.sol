//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract smartContract{


    struct PatientRegister{
        string AadhaarCardNo;
        string name;
        address addr;
        uint date;
    }

    struct DoctorRegister{
        string AadhaarCardNo;
        string name;
        string Hospital;        
        address addr;
        uint date;
    }

    struct Appointments{
        address doctoraddr;
        address patientaddr;        
        string diagnosis;
        uint creationDate;
    }

    struct InsuranceCompany {
        string Companyname;
        address addr;
        uint date;
    }

    struct ResearchOrganization {
        string OrganizationName;
        address addr;
        uint date;
    }

    //Array to store address of respective roles
    address[] public patientList;
    address[] public doctorList;
    address[] public appointmentList;
    address[] public insuranceCompanyList;
    address[] public researchOrganizationList;

    //Count of respective roles
    uint256 public patientCount = 0;
    uint256 public doctorCount = 0;
    uint256 public appointmentCount = 0;
    uint256 public insuranceCompanyCount = 0;
    uint256 public researchOrganizationCount = 0;


    //to store patient information keyed by their Ethereum addresses. For example, patients[address] would give access to the PatientRegister struct associated with the given address, allowing the contract to retrieve or update the information of a specific patient based on their Ethereum address.
    mapping(address => PatientRegister) patients;
    mapping(address => DoctorRegister) doctors;
    mapping(address => Appointments) appointments;
    mapping(address => InsuranceCompany) insuranceCompanies;
    mapping(address => ResearchOrganization) researchOrganizations;


    //managing permissions or approvals between two entities represented by Ethereum addresses. It allows for efficient checking of approval status between pairs of addresses.
    mapping(address=>mapping(address=>bool)) isApproved;


    //Check whether given address is patient or not
    mapping(address => bool) isPatient;
    mapping(address => bool) isDoctor;
    mapping(address => uint) AppointmentPerPatient;
    mapping(address => uint) permissionGrantedCount;


    //Retrieve patient details from patient sign up page and store the details into the blockchain
    function SetPatientRegData(string memory _AadhaarCardNo, string memory _name) public {
        require(!isPatient[msg.sender]);
        PatientRegister storage p = patients[msg.sender];
        
        p.AadhaarCardNo = _AadhaarCardNo;
        p.name = _name;
        p.addr = msg.sender;
        p.date = block.timestamp;
        
        patientList.push(msg.sender);
        isPatient[msg.sender] = true;
        isApproved[msg.sender][msg.sender] = true;
        patientCount++;
    }

    //Retrieve Doctor details from doctor registration page and store the details into the blockchain
    function SetDoctorRegData(string memory _AadhaarCardNo, string memory _name, string memory _Hospital) public {
        require(!isDoctor[msg.sender]);
        DoctorRegister storage d = doctors[msg.sender];
        
        d.AadhaarCardNo = _AadhaarCardNo;
        d.name = _name;
        d.Hospital = _Hospital;
        d.addr = msg.sender;
        d.date = block.timestamp;
        
        doctorList.push(msg.sender);
        isDoctor[msg.sender] = true;
        doctorCount++;
    }

    //Retrieve appointment details from appointment page and store the details into the blockchain
    function setAppointment(address _addr, string memory _diagnosis ) public {
        require(isDoctor[msg.sender]);
        Appointments storage a = appointments[_addr];
        
        a.doctoraddr = msg.sender;
        a.patientaddr = _addr;
        a.diagnosis = _diagnosis;
        a.creationDate = block.timestamp;

        appointmentList.push(_addr);
        appointmentCount++;
        AppointmentPerPatient[_addr]++;
    }

    // Function for insurance company to register on the portal
    function registerInsuranceCompany(string memory _name) public {
        require(insuranceCompanies[msg.sender].addr == address(0), "Insurance company already registered.");
        insuranceCompanies[msg.sender] = InsuranceCompany(_name, msg.sender, block.timestamp);
        insuranceCompanyList.push(msg.sender);
        insuranceCompanyCount++;
    }

    // Function for research organization to register on the portal
    function registerResearchOrganization(string memory _name) public {
        require(researchOrganizations[msg.sender].addr == address(0), "Research organization already registered.");
        researchOrganizations[msg.sender] = ResearchOrganization(_name, msg.sender, block.timestamp);
        researchOrganizationList.push(msg.sender);
        researchOrganizationCount++;
    }

   

    //Owner of the record must give permission to doctor only they are allowed to view records
    function givePermission(address _address) public returns(bool success) {
        isApproved[msg.sender][_address] = true;
        permissionGrantedCount[_address]++;
        return true;
    }

   //patients to grant permission to research organizations.
    function grantPermission(address _researchOrganization) public {
        require(isPatient[msg.sender], "Only patients can grant permission.");
        require(researchOrganizations[_researchOrganization].addr != address(0), "Research organization not registered.");
        isApproved[msg.sender][_researchOrganization] = true;
    }
   
    //Owner of the record can take away the permission granted to doctors to view records
    function RevokePermission(address _address) public returns(bool success) {
        isApproved[msg.sender][_address] = false;
        permissionGrantedCount[_address]--;
        return true;
    }


    //Retrieve a list of all doctors address
    function getDoctors() public view returns(address[] memory) {
        return doctorList;
    }

    //Search patient details by entering a patient address (Only record owner or doctor with permission will be allowed to access)
    function searchPatientDemographic(address _address) public view returns(string memory, string memory, address, uint256) {
        require(isApproved[_address][msg.sender]);
        
        PatientRegister storage p = patients[_address];
        
        return (p.AadhaarCardNo, p.name, p.addr, p.date);
    }

    //Search doctor details by entering a doctor address 
    function searchDoctorsbyDoctor(address _address) public view returns(string memory, string memory, string memory, address) {
        require(isDoctor[_address]);
        
        DoctorRegister storage d = doctors[_address];
        
        return (d.AadhaarCardNo, d.name, d.Hospital, d.addr);
    }

    //Search doctor details by entering a patient address 
    function searchDoctorsbyPatient(address _address) public view returns(string memory, string memory, string memory, address) {
        require(isPatient[_address]);
        
        DoctorRegister storage d = doctors[_address];
        
        return (d.AadhaarCardNo, d.name, d.Hospital, d.addr);
    }
    
   //Search appointment details by entering a patient address
    function searchAppointment(address _address) public view returns(address, string memory, uint256, string memory) {
        Appointments storage a = appointments[_address];
        DoctorRegister storage d = doctors[a.doctoraddr];

        return (a.doctoraddr, d.name, a.creationDate, a.diagnosis);
    }


    

    //Retrieve patient count
    function getPatientCount() public view returns(uint256) {
        return patientCount;
    }

    //Retrieve doctor count
    function getDoctorCount() public view returns(uint256) {
        return doctorCount;
    }

    //Retrieve appointment count
    function getAppointmentCount() public view returns(uint256) {
        return appointmentCount;
    }


    //Retrieve permission granted count
    function getAppointmentPerPatient(address _address) public view returns(uint256) {
        return AppointmentPerPatient[_address];
    }    



    //Insurance functions,,,,,,,,,,,,................................................................................./////////////////////////////////////////////////////////////////
    
    
     // Function for insurance company to request permission from user to access medical records
    function requestPermission(address _userAddress) public {
        require(isPatient[_userAddress], "User address is not registered as a patient.");
        require(!isApproved[msg.sender][_userAddress], "Permission already granted.");
        
        isApproved[msg.sender][_userAddress] = true;
        permissionGrantedCount[_userAddress]++;
    }

    // Function for patient to revoke permission granted to insurance company
    function revokePermission(address _insuranceCompanyAddress) public {
        require(isApproved[_insuranceCompanyAddress][msg.sender], "Permission not granted to revoke.");
        
        isApproved[_insuranceCompanyAddress][msg.sender] = false;
        permissionGrantedCount[msg.sender]--;
    }

    //Research Organization Part .................../////,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.........................................
    
    // Get Diagnoses List
    function getDiagnoses() public view returns(string[] memory) {
        require(researchOrganizations[msg.sender].addr != address(0), "Only registered research organizations can access diagnoses.");
        
        string[] memory diagnoses = new string[](appointmentList.length);
        for (uint i = 0; i < appointmentList.length; i++) {
            address appointmentAddr = appointmentList[i];
            Appointments storage appointment = appointments[appointmentAddr];
            diagnoses[i] = appointment.diagnosis;
        }
        return diagnoses;
    }


    //Get Patients' Diagnoses by Patient Address:
    // This function allows research organizations to retrieve the diagnoses of all appointments for a specific patient.
    function getPatientDiagnoses(address _patientAddress) public view returns(string[] memory) {
        require(researchOrganizations[msg.sender].addr != address(0), "Only registered research organizations can access patient diagnoses.");
        require(isPatient[_patientAddress], "Patient address is not registered.");
        require(isApproved[_patientAddress][msg.sender], "Permission not granted.");

        string[] memory patientDiagnoses = new string[](AppointmentPerPatient[_patientAddress]);
        uint index = 0;
        for (uint i = 0; i < appointmentList.length; i++) {
            address appointmentAddr = appointmentList[i];
            Appointments storage appointment = appointments[appointmentAddr];
            if (appointment.patientaddr == _patientAddress) {
                patientDiagnoses[index++] = appointment.diagnosis;
            }
        }
        return patientDiagnoses;
    }
    

   

}