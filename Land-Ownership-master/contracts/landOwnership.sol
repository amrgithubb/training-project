pragma solidity >=0.4.0 <0.6.0;

contract landOwnership {
    struct landDetails {
        string landAddress;
        string province;
        uint256 surveyNumber;
        address payable CurrentOwner;
        uint256 marketValue;
        bool isAvailable;
        address requester;
        reqStatus requestStatus;
    }
    enum reqStatus {Default, pending, rejected, approved}

    struct ownerAssets {
        uint256[] listOfAssets;
    }

    mapping(uint256 => landDetails) land;
    address owner;
    mapping(string => address) admin;
    mapping(address => ownerAssets) ownersAssets;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    //adding province admins
    function addAdmin(address _admin, string memory _province)
        public
        onlyOwner
    {
        admin[_province] = _admin;
    }

    function Registration(
        string memory _landAddress,
        string memory _province,
        uint256 _surveyNumber,
        address payable _OwnerAddress,
        uint256 _marketValue,
        uint256 id
    ) public returns (bool) {
        require(admin[_province] == msg.sender || owner == msg.sender);
        land[id].landAddress = _landAddress;
        land[id].province = _province;
        land[id].surveyNumber = _surveyNumber;
        land[id].CurrentOwner = _OwnerAddress;
        land[id].marketValue = _marketValue;
        ownersAssets[_OwnerAddress].listOfAssets.push(id);
        return true;
    }

    function computeId(
        string memory _landAddress,
        string memory _province,
        uint256 _surveyNumber
    ) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(_landAddress, _province, _surveyNumber)
                )
            ) % 10000000000000;
    }

    function landInfoForOwner(uint256 id)
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            bool,
            address,
            reqStatus
        )
    {
        return (
            land[id].landAddress,
            land[id].province,
            land[id].surveyNumber,
            land[id].isAvailable,
            land[id].requester,
            land[id].requestStatus
        );
    }

    function landInfoForBuyer(uint256 id)
        public
        view
        returns (
            address,
            uint256,
            bool,
            address,
            reqStatus
        )
    {
        return (
            land[id].CurrentOwner,
            land[id].marketValue,
            land[id].isAvailable,
            land[id].requester,
            land[id].requestStatus
        );
    }

    function requstToLandOwner(uint256 id) public {
        require(land[id].isAvailable);
        land[id].requester = msg.sender;
        land[id].isAvailable = false;
        land[id].requestStatus = reqStatus.pending; //changes the status to pending.
    }

    function viewAssets() public view returns (uint256[] memory) {
        return (ownersAssets[msg.sender].listOfAssets);
    }

    function viewRequest(uint256 property) public view returns (address) {
        return (land[property].requester);
    }

    function processRequest(uint256 property, reqStatus status) public {
        require(land[property].CurrentOwner == msg.sender);
        land[property].requestStatus = status;
        if (status == reqStatus.rejected) {
            land[property].requester = address(0);
            land[property].requestStatus = reqStatus.Default;
        }
    }

    function makeAvailable(uint256 property) public {
        require(land[property].CurrentOwner == msg.sender);
        land[property].isAvailable = true;
    }

    function buyProperty(uint256 property) public payable {
        require(land[property].requestStatus == reqStatus.approved);
        require(
            msg.value >=
                (land[property].marketValue +
                    ((land[property].marketValue) / 10))
        );
        land[property].CurrentOwner.transfer(land[property].marketValue);
        removeOwnership(land[property].CurrentOwner, property);
        land[property].CurrentOwner = msg.sender;
        land[property].isAvailable = false;
        land[property].requester = address(0);
        land[property].requestStatus = reqStatus.Default;
        ownersAssets[msg.sender].listOfAssets.push(property); //adds the property to the asset list of the new owner.
    }

    function removeOwnership(address previousOwner, uint256 id) private {
        uint256 index = findId(id, previousOwner);
        ownersAssets[previousOwner]
            .listOfAssets[index] = ownersAssets[previousOwner]
            .listOfAssets[ownersAssets[previousOwner].listOfAssets.length - 1];
        delete ownersAssets[previousOwner]
            .listOfAssets[ownersAssets[previousOwner].listOfAssets.length - 1];
        ownersAssets[previousOwner].listOfAssets.length--;
    }

    function findId(uint256 id, address user) public view returns (uint256) {
        uint256 i;
        for (i = 0; i < ownersAssets[user].listOfAssets.length; i++) {
            if (ownersAssets[user].listOfAssets[i] == id) return i;
        }
        return i;
    }
}
