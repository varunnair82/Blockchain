// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.0 <0.7.0;

/** 
 * @title Voting with Blockchain
 * @dev Implements election & voting process.
 */
contract Election {

    address private admin;

    enum ElectionState {NOTSTARTED, ONGOING, COMPLETED}

    struct Voter{
        uint id;
        string name;
        bool voted;
        uint vote;
        address[] delegatefrom;
    }

    struct Candidate{
        uint id;
        string name;
        string proposal;
        uint voteCount;
    }

    ElectionState electionState;
    mapping(address => Voter) voters;    
    uint public voterCount;
    Candidate[]  candidates;

    constructor() public {
        admin = msg.sender;
        electionState = ElectionState.NOTSTARTED;
    }

    function addCandidate(string memory _name, string memory _proposal) public {
        require(
            msg.sender == admin,
            "Only admin can add a Candidate."
        );
        require(
            electionState != ElectionState.ONGOING,
            "Can not add a Candidate when Election is ongoing."
        );
        require(
            bytes(_name).length != 0 && bytes(_proposal).length != 0,
            "Please provide name of the candidate"
        );

        candidates.push(Candidate({
            id: candidates.length,
            name: _name,
            proposal: _proposal,
            voteCount: 0
        }));
    }

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

    function delegateVote(address _delegate) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(_delegate != msg.sender, "Self-delegation is disallowed.");

        for (uint i = 0; i < voters[_delegate].delegatefrom.length; i++) {
            require(voters[_delegate].delegatefrom[i] != msg.sender, "Found loop in delegation.");
        }
               

        if(voters[_delegate].voted){
            sender.voted = true;
            sender.vote = voters[_delegate].vote;
        } else{
            voters[_delegate].delegatefrom.push(msg.sender);
        }
    }

    function endElection() public {
        require(
            msg.sender == admin,
            "Only admin can end the election."
        );
        electionState = ElectionState.COMPLETED;
    }

    function startElection() public {
        require(
            msg.sender == admin,
            "Only admin can start the election."
        );
        electionState = ElectionState.ONGOING;
    }

    function vote(uint _candidateID) public {
        Voter storage sender = voters[msg.sender];   
        require(electionState == ElectionState.ONGOING, "Can not vote until election starts.");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = _candidateID;

        candidates[_candidateID].voteCount += 1;

        for (uint i = 0; i < sender.delegatefrom.length; i++) {
            voters[sender.delegatefrom[i]].vote = _candidateID;
            voters[sender.delegatefrom[i]].voted = true;

            candidates[_candidateID].voteCount += 1;
        }
    }

    function candidateCount() view public returns(uint){
        return (candidates.length);
    }

    function checkState() view public returns(ElectionState){
        return(electionState);
    }

    function displayCandidate(uint _id) view public returns(uint, string memory, string memory){
        return (candidates[_id].id, candidates[_id].name, candidates[_id].proposal);
    }

    function getVoter(address _voter) view public returns(uint, string memory) {

        return(voters[_voter].id, voters[_voter].name);

    }

    function showResult(uint _id) view public returns(uint, string memory, uint){
        return (candidates[_id].id, candidates[_id].name, candidates[_id].voteCount);
    }

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

    function voterProfile(address _voter) view public returns(uint, string memory, uint, string memory, uint) {
        require(
            electionState != ElectionState.COMPLETED,
            "Only Admin can view voter profile."
        );
        Voter memory v = voters[_voter];
        return(v.id, v.name, v.vote, candidates[v.vote].name, v.delegatefrom.length);        
    }


}