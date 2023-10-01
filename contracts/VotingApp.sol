// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.9;
contract VotingApp{
     /*///////////////////////////////////////////////////////////////
                        STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    address private owner;
    uint256 private userIndex; 
    uint256 private electionIndex; 
    uint256 private votingPeriod;
    bool private votingStarted;
    uint256 private votingStart;
    uint256 private votingEnd;
    uint256 private voteCount;
     /*///////////////////////////////////////////////////////////////
                        STRUCTURES
    //////////////////////////////////////////////////////////////*/
    struct Candidate{
        uint256 id;
        string name;
        address swisstronikAccount;
        bool voted;    
    }
    struct Election{
        uint256 id;
        string topic;
        string decision;
        bool finished;
    }
     /*///////////////////////////////////////////////////////////////
                        ARRAYS
    //////////////////////////////////////////////////////////////*/
    Candidate[] private candidates;
    Election[] private elections;
    string[] private votes;  
    string[] private options;
    address[] private registeredUsers;
     /*///////////////////////////////////////////////////////////////
                        MAPPINGS
    //////////////////////////////////////////////////////////////*/
    mapping (address => bool) blackList;
    mapping (address => bool) checkUserRegistration;
    mapping (address => string) userNames;
    mapping (address => uint256) showUserId;
    mapping (address => bool) voted;
     /*///////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
       constructor() {
        owner = msg.sender;
        checkUserRegistration[owner]=true;
        electionIndex = 0;
        userIndex= 0;
        votingStarted =false;
    }
     /*///////////////////////////////////////////////////////////////
                        CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/
    error electionDidNotFinish();
    error electionDidNotStart();
    error userNotRegistered(address user);
    error userBanned(address user);
    error callerIsNotOwner(address caller);
    error invalidArrayRange();
    error invalidVote();
    error insufficientParameter();
    error userAlreadyRegistered();
     /*///////////////////////////////////////////////////////////////
                        EVENT
    //////////////////////////////////////////////////////////////*/ 
    event unAuthorizedAccessAttempt(address user);
     /*///////////////////////////////////////////////////////////////
                        MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier onlyUsers{
        if(checkUserRegistration[msg.sender]!=true){
            emit unAuthorizedAccessAttempt(msg.sender);
            revert userNotRegistered(msg.sender);
        }
         if(blackList[msg.sender]==true){
            revert userBanned(msg.sender);
        }
        _;
    }
     /*///////////////////////////////////////////////////////////////
                        PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev _checkElectionState() will check if election finished if false it will throw an exception
     */
    function _checkElectionState() private view{
        if(votingStarted==true){
            revert electionDidNotFinish();
        }
    }
    /**
     * @dev _onlyOwner() will work like a modifier and ensure that caller is owner
     */
    function _onlyOwner() private{
          if(msg.sender!=owner){
            emit unAuthorizedAccessAttempt(msg.sender);
            revert callerIsNotOwner(msg.sender);
        }
    }
     /*///////////////////////////////////////////////////////////////
                        PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev it grants ownership to a new user
     * @notice only owner can call this function
     * @param newOwner should be address of new owner
     */
    function renounceOwnership(address newOwner) public{    
        _onlyOwner();
        owner = newOwner;
        if(!checkUserRegistration[owner]){
            checkUserRegistration[owner]=true;
        }
    } 
    /**
     * @dev   It launches new elections
     * @param _votingPeriod will be im minute format
     * e.g 1440 for 1 day minutes by following logic 1 hour = 60 minutes so 24 hour 1440 minutes
     * @param _topic will be context of current voting 
     * @param _options  will be voting options which are set by contract owner 
     * @notice Only owner can call this function
     */
    function startElection(
        uint256 _votingPeriod,
        string memory _topic,
        string[] memory _options) public {
        _onlyOwner();
        _checkElectionState();
        if(_options.length<2){
            revert insufficientParameter();
        }
        //Each candidate should have a name and address
        delete options;
        options=_options;
        elections.push(Election({id : electionIndex, topic: _topic, decision : "", finished : false}));
        electionIndex++;
        //start election after candidates are added 
        votingStarted=true;
        votingStart = block.timestamp;
        votingEnd = block.timestamp + _votingPeriod * 1 minutes;
        }
     
    /**
     * @dev This function adds new voters to current election
     * @param _candidate name of voter who will be added 
     * @param _candidateAddress address of voter who will be added
     * @notice When a voter added that voter will be able to vote in future elections as well  
     * @notice Only owner can call this function
     */
    function addVoter(string memory _candidate,address _candidateAddress) public{
        _onlyOwner();
        if(checkUserRegistration[_candidateAddress]){
            revert userAlreadyRegistered();
        }
        candidates.push(
            Candidate({id : candidates.length, name : _candidate, swisstronikAccount : _candidateAddress, voted :false})
        );
        checkUserRegistration[_candidateAddress]=true;
        registeredUsers.push(candidates[candidates.length-1].swisstronikAccount);
        showUserId[candidates[candidates.length-1].swisstronikAccount]=candidates.length-1;
        userNames[_candidateAddress]=_candidate;
        userIndex++;
            
        }
    /**
     * @dev This function will use by users and owner to cast their vote
     * @param _vote It should be equal to one of the options and in string format
     * @notice All voters can vote only once even if function can call multiple times caller 
     * can submit his vote only once
     * @notice Users in blacklist can't vote 
     */

    function vote(string memory _vote) public onlyUsers{
        if(votingStarted==false){
            revert electionDidNotFinish();
        }
        bool isValid=false;
        if(voted[msg.sender]==false){
            uint256 i = 0;
                    while(i<options.length){
                        if(keccak256(bytes(options[i])) == keccak256(bytes(_vote))){
                            isValid=true;
                            break;
                        }
                        i++;
                    }
                    if(!isValid){
                        revert invalidVote(); 
                    }
            votes.push(_vote);
            voteCount++;
            voted[msg.sender]=true;
        } 
    }
    /**
     * @dev This function will use to blacklist the users who attempt violating community guidelines 
     * @param _user is the address of user who violates community guidelines
     */
    function banUser(address _user) public{
                _onlyOwner();
                blackList[_user]=true;
                delete candidates[showUserId[_user]];
    }
    /**
     * @dev It will show how many time rest to the end of election
     * @notice This function will be used by checkElectionPeriod()
     * @notice It will return result in second format 
     */
    function electionTimer() public view returns(uint256){
        if(block.timestamp >= votingEnd){
            return 0;
        }
        return(votingEnd - block.timestamp);
    }
    /**
     * @dev It calls electionTimer() and returns true if election is ongoing
     */
    function checkElectionPeriod() public returns(bool){
        if(electionTimer() > 0){
            return true;
        }
        votingStarted = false;
        return false;
    }
    /**
     * @dev votingResult() will return the result of latest finished election
     */
    function votingResult() public returns(string memory){
        if(checkElectionPeriod()){
            revert electionDidNotFinish();
        }
        uint256 tmp=0;
        uint256 ptr=0;
        string memory winner;
        for(uint256 i=0;i<options.length;i++){
            ptr=0;
            for(uint256 j=0;j<votes.length;j++){
                if(keccak256(bytes(votes[j]))==keccak256(bytes(options[i]))){
                    ptr++;
                }
            }
            winner = ptr>tmp?options[i]:winner;
            tmp=ptr;
        }
        elections[electionIndex-1].decision=winner;
        elections[electionIndex-1].finished=true;
        votingStarted=false;
        return winner;
    }
     /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev It gets a user address and returns his name as output
     * @param _user Address of user
     */
    function showVoter(address _user) external view returns(string memory){
        if(msg.sender != owner || checkUserRegistration[msg.sender] == false ){
            revert userNotRegistered(msg.sender);
        }
        return(userNames[_user]);
    }
    /**
     * @dev Count how many user voted in the ongoing election 
     */
    function countVotes() external  view returns(uint256){
        return voteCount;
    }
    /**
     * @dev Shows options which users can submit as their vote
     * @notice Anything other than these options won't accept as vote
     */
     function showOptions() external view returns(string[] memory){
        return  options;
    }
    /**
     * @dev This function will show old election results
     * @param id Election id 
     */
    function showOldElectionResult(uint256 id) external view returns(string memory){
        return(elections[id].decision);
    }
     /**
     * @dev This function will show old election topics
     * @param id Election id 
     */
    function showOldElectionTopic(uint256 id) external view returns(string memory){
        return(elections[id].topic);
    }
     /**
     * @dev This function will show the address of users who are registered
     * @notice Even if a user is registered he can't cast his vote in case he is in blacklist.
     */
    function showRegisteredUsers() external view returns(address[] memory){
        return registeredUsers;
    }
    /**
     * @dev Returns contract owner
     */
    function Owner() external view  returns(address){
        return owner;
    }  
}