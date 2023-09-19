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
    }

    struct Candidate{
        uint id;
        string name;
        string proposal;
    }

    ElectionState electionState;
    mapping(address => Voter) voters;    
    Candidate[]  candidates;

    constructor() public {
        admin = msg.sender;
        electionState = ElectionState.NOTSTARTED;
    }

    uint mapSize;

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

       mapSize++;
    }

    function getVoter(address _voter) view public returns(uint, string memory) {

        return(voters[_voter].id, voters[_voter].name);

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

        candidates.push(Candidate({
            id: candidates.length,
            name: _name,
            proposal: _proposal
        }));
    }

    function displayCandidate(uint _id) view public returns(uint, string memory, string memory){
        return (candidates[_id].id, candidates[_id].name, candidates[_id].proposal);
    }

    function candidate_count() view public returns(uint){
        return (candidates.length);
    }


    function startElection() public {
        require(
            msg.sender == admin,
            "Only admin can start the election."
        );
        electionState = ElectionState.ONGOING;
    }

    function endElection() public {
        require(
            msg.sender == admin,
            "Only admin can end the election."
        );
        electionState = ElectionState.COMPLETED;
    }

    function vote(uint _candidateID) public {
        Voter storage sender = voters[msg.sender];   
        require(electionState == ElectionState.ONGOING, "Can not vote until election starts.");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = _candidateID;
    }
}