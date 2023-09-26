// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.0 <0.7.0;

/** 
 * @title Voting with Blockchain
 * @dev Implements election & voting process.
 */
contract Election {

    // Contract admin address
    address private admin;

    // Enumeration for election states
    enum ElectionState {NOTSTARTED, ONGOING, COMPLETED}

    // Struct to represent a voter
    struct Voter{
        uint id;
        string name;
        bool voted;
        uint vote;
        address delegate;
    }

    // Struct to represent a candidate
    struct Candidate{
        uint id;
        string name;
        string proposal;
        uint voteCount;
    }

    // Current state of the election
    ElectionState electionState;

    // Mapping of ElectionState to string value
    mapping(uint8 => string) private electionStateToString;

    // Mapping of voter addresses to voter data
    mapping(address => Voter) voters;

    // Total count of voters
    uint public voterCount;

    // Array to store candidate data
    Candidate[] candidates;

    // Constructor to initialize contract admin and set the initial state
    constructor() public {
        admin = msg.sender;
        electionState = ElectionState.NOTSTARTED;
        
        // Initialize the mapping with string representations
        electionStateToString[uint8(ElectionState.NOTSTARTED)] = "NOTSTARTED";
        electionStateToString[uint8(ElectionState.ONGOING)] = "ONGOING";
        electionStateToString[uint8(ElectionState.COMPLETED)] = "COMPLETED";
    }

    // Event to log when the election starts
    event ElectionStarted(string);

    // Event to log when the election ends
    event ElectionEnded(string);

    // Function to add a candidate
    function addCandidate(string memory _name, string memory _proposal) public {
        // Only admin can add a candidate
        require(msg.sender == admin, "Only admin can add a Candidate.");
        // Candidates can only be added before the election starts
        require(electionState != ElectionState.ONGOING, "Can not add a Candidate when Election is ongoing.");
        require(bytes(_name).length != 0 && bytes(_proposal).length != 0, "Please provide name of the candidate");

        candidates.push(Candidate({
            id: candidates.length+1,
            name: _name,
            proposal: _proposal,
            voteCount: 0
        }));
    }

    // Function to add a voter
    function addVoter(uint _id, string memory _name, address _voter) public {
        require(
            msg.sender == admin,
            "Only admin can add a voter."
        );
        require(
            electionState != ElectionState.ONGOING,
            "Can not add a voter when Election is ongoing."
        );

       voters[_voter].id = _id;
       voters[_voter].name = _name;

       voterCount++;
    }

    // Function to delegate a vote to another address
    function delegateVote(address _delegate) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(_delegate != msg.sender, "Self-delegation is disallowed.");

        require(voters[_delegate].delegate != msg.sender, "Found loop in delegation.");
        
        voters[msg.sender].delegate = _delegate;
    }

    // Function to end the election (admin only)
    function endElection() public {
        require(
            msg.sender == admin,
            "Only admin can end the election."
        );
        electionState = ElectionState.COMPLETED;

        emit ElectionEnded("Election Ended");
    }

    // Function to start the election (admin only)
    function startElection() public {
        require(
            msg.sender == admin,
            "Only admin can start the election."
        );
        electionState = ElectionState.ONGOING;

        emit ElectionStarted("Election Started");
    }

    // Function to cast a vote
    function vote(uint _candidateID) public {
        require(_candidateID > 0 && _candidateID <= candidates.length, "Invalid Candidate id");
        _candidateID = _candidateID - 1;

        Voter storage sender = voters[msg.sender];   
        require(electionState == ElectionState.ONGOING, "Can not vote until election starts.");

            require(!sender.voted, "Already voted.");
            sender.voted = true;
            sender.vote = candidates[_candidateID].id;

            candidates[_candidateID].voteCount += 1;
    }

    // Function to cast a vote on behalf of the voter who has delegated the voting rights.
    function voteAsDelegate(uint _candidateID, address _voter) public {
        require(_candidateID > 0 && _candidateID <= candidates.length, "Invalid Candidate id");
        _candidateID = _candidateID - 1;

        require(electionState == ElectionState.ONGOING, "Can not vote until election starts.");

        require(voters[_voter].delegate == msg.sender, "You are not delegated to vote on behlf of the Voter");

        require(!voters[_voter].voted, "You have already voted can not delegate.");

            voters[_voter].voted = true;
            voters[_voter].vote = candidates[_candidateID].id;

            candidates[_candidateID].voteCount += 1;
    }

    // Function to get the count of candidates
    function candidateCount() view public returns(uint){
        return (candidates.length);
    }

    // Function to check the current state of the election
    function checkState() view public returns(string memory){
        return electionStateToString[uint8(electionState)];
    }

    // Function to display candidate details
    function displayCandidate(uint _id) view public returns(uint, string memory, string memory){
        require(_id > 0 && _id <= candidates.length, "Invalid Candidate id");
        return (candidates[_id-1].id, candidates[_id-1].name, candidates[_id-1].proposal);
    }

    // Function to get voter details by address
    function getVoter(address _voter) view public returns(uint, string memory) {
        require(bytes(voters[_voter].name).length != 0, "Invalid Voter Address.");
        return(voters[_voter].id, voters[_voter].name);
    }

    // Function to display candidate vote count
    function showResult(uint _id) view public returns(uint, string memory, uint){
        require(_id > 0 && _id <= candidates.length, "Invalid Candidate id");
        _id = _id -1;
        return (candidates[_id].id, candidates[_id].name, candidates[_id].voteCount);
    }

    // Function to display the winner of the election
    function showWinner() view public returns(string memory, uint, uint){
        require(
            electionState == ElectionState.COMPLETED,
            "Only Admin can show the winner."
        );

        require(candidates.length > 0, "Candidates list is empty.");

        Candidate memory winner = candidates[0]; // Initialize winner with the first element

        for (uint256 i = 1; i < candidates.length; i++) {
            if (candidates[i].voteCount > winner.voteCount) {
                winner = candidates[i];
            }
        }

        return(winner.name, winner.id, winner.voteCount);
    }

    // Function to view voter profile (admin only, not available after election completion)
    function voterProfile(address _voter) view public returns(uint, string memory, uint, string memory, address) {
        require(
             msg.sender == admin,
            "Only Admin can view voter profile."
        );
        Voter memory v = voters[_voter];
        return(v.id, v.name, v.vote, candidates[v.vote].name, v.delegate);        
    }

}