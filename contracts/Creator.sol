pragma solidity ^0.4.19;

contract Voting {

    struct Ballot {
        uint8 ballotType;
        uint32 ballotId;
        uint8 voteLimit;
        uint32 timeLimit;
        string title;
        uint8 whitelist;
        uint8 votesToWin;
        uint8 ended;
    }

    struct Candidates {
        bytes32[] candidateList;
        mapping (bytes32 => bytes32) candidateHash;
        mapping (bytes32 => uint256) votesReceived;
    }

    struct Voter {
        bytes32[] whitelisted;
        mapping (address => uint8) attemptedVotes;
    }

    Candidates c;
    Voter v;
    Ballot b;

    string convertCandidate;
    string tempTitle;
    bytes32 tempCandidate;
    uint256 tempVote;
    bytes32 tempHash;
    uint256[] tempVotes;
    bytes32[] tempCandidates;
    bytes32 tempEmail;
    address owner;
    uint8 winningpVote;
    uint8 runneruppVote;
    uint8 losingpVote;

    function Voting(uint32 _timeLimit, uint8 _ballotType, uint8 _voteLimit, uint32 _ballotId, string _title, uint8 _whitelist, uint8 _votesToWin, address _owner) public {
        b.timeLimit = _timeLimit;
        b.ballotType = _ballotType;
        b.voteLimit = _voteLimit;
        b.ballotId = _ballotId;
        b.title = _title;
        b.whitelist = _whitelist;
        b.votesToWin = _votesToWin;
        b.ended = 0;

        owner = _owner;
        winningpVote = 0;
        runneruppVote = 0;
        losingpVote = 0;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event DelayVoting();

    function setCandidates(bytes32[] _candidates) public onlyOwner {
        for(uint i = 0; i < _candidates.length; i++) {
            tempCandidate = _candidates[i];
            c.candidateList.push(tempCandidate);
        }
    }

    function setWhitelisted(bytes32[] _emails) public onlyOwner {
        for(uint i = 0; i < _emails.length; i++) {
            tempEmail = _emails[i];
            v.whitelisted.push(tempEmail);
        }
    }

    function hashCandidates() public onlyOwner {
        tempVote = 1;
        for(uint i = 0; i < c.candidateList.length; i++) {
            tempCandidate = c.candidateList[i];
            convertCandidate = bytes32ToString(tempCandidate);
            c.candidateHash[tempCandidate] = keccak256(convertCandidate);
            c.votesReceived[keccak256(convertCandidate)] = tempVote;
        }
    }

    function voteForCandidate(uint256[] _votes, bytes32 _email, bytes32[] _candidates) public {
        if (checkTimelimit() == false || checkVoteattempts() == false) revert();
        if (checkWhitelist() == true && checkifWhitelisted(_email) == false) revert();
        if (b.ended == 1) revert();
        tempVotes = _votes;
        tempCandidates = _candidates;
        v.attemptedVotes[msg.sender] += 1;

        for(uint i = 0; i < tempCandidates.length; i++) {
            tempCandidate = tempCandidates[i];
            tempHash = c.candidateHash[tempCandidate];
            if (validCandidate(tempHash) == false) revert();
            tempVote = tempVotes[i];
            c.votesReceived[tempHash] = tempVote;
        }
    }

    function votesFor(bytes32 cHash) public view returns (uint256){
        if (validCandidate(cHash) == false) revert();
        return c.votesReceived[cHash];
    }

    function totalVotesFor(bytes32 cHash) public view returns (uint256){
        if (checkBallottype() == false && checkTimelimit() == true) return 0;
        if (validCandidate(cHash) == false) revert();
        return c.votesReceived[cHash];
    }

    function bytes32ToString(bytes32 x) private pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function validCandidate(bytes32 cHash) public view returns (bool) {
        for(uint k = 0; k < c.candidateList.length; k++) {
            tempCandidate = c.candidateList[k];
            if (c.candidateHash[tempCandidate] == cHash) {
                return true;
            }
        }
        return false;
    }

    function candidateList(uint64 _ballotID) public view returns (bytes32[]) {
        if (checkballotID(_ballotID) == false) revert();
        return c.candidateList;
    }

    function checkTimelimit() public view returns (bool) {
        if (block.timestamp >= b.timeLimit) return false;
        else return true;
    }

    function checkVotesToWin(bytes32 cHash) public view returns (uint256) {
        if (validCandidate(cHash) == false) revert();
        return c.votesReceived[cHash];
    }

    function checkBallottype() private view returns (bool) {
        if (b.ballotType == 1) return false;
        else return true;
    }

    function checkballotID(uint64 ballotID) private view returns (bool) {
        if (ballotID == b.ballotId) return true;
        else return false;
    }

    function checkVoteattempts() public view returns (bool) {
        if (v.attemptedVotes[msg.sender] == b.voteLimit) return false;
        else return true;
    }

    function checkWhitelist() public view returns (bool) {
        if (b.whitelist == 1) return true;
        else return false;
    }

    function checkifWhitelisted(bytes32 email) public view returns (bool) {
        for(uint j = 0; j < v.whitelisted.length; j++) {
            tempEmail = v.whitelisted[j];
            if (tempEmail == email) {
                return true;
            }
        }
        return false;
    }

    function getTimelimit() public view returns (uint32) {
        return b.timeLimit;
    }

    function getTitle() public view returns (string) {
        return b.title;
    }

    function getBallotType() public view returns (uint8) {
        return b.ballotType;
    }

    function getVotesToWin() public view returns (uint8) {
        return b.votesToWin;
    }

    function getBallotStatus() public view returns (uint8) {
        return b.ended;
    }

    function changeBallotStatus() public {
        b.ended = 1;
    }

    function addVoteForWinning(bytes32 _email) public {
        if (checkTimelimit() == false || checkVoteattempts() == false) revert();
        if (checkWhitelist() == true && checkifWhitelisted(_email) == false) revert();
        if (b.ended == 1) revert();
        v.attemptedVotes[msg.sender] += 1;

        winningpVote++;
    }

    function addVoteForRunnerUp(bytes32 _email) public {
        if (checkTimelimit() == false || checkVoteattempts() == false) revert();
        if (checkWhitelist() == true && checkifWhitelisted(_email) == false) revert();
        if (b.ended == 1) revert();
        v.attemptedVotes[msg.sender] += 1;

        runneruppVote++;
    }

    function addVoteForLosing(bytes32 _email) public {
        if (checkTimelimit() == false || checkVoteattempts() == false) revert();
        if (checkWhitelist() == true && checkifWhitelisted(_email) == false) revert();
        if (b.ended == 1) revert();
        v.attemptedVotes[msg.sender] += 1;

        losingpVote++;
    }

    function getpVotesWinning() public view returns (uint8) {
        return winningpVote;
    }

    function getpVotesRunnerUp() public view returns (uint8) {
        return runneruppVote;
    }

    function getpVotesLosing() public view returns (uint8) {
        return losingpVote;
    }
}


//                         //
//Start of Creator contract//
//                         //

contract Creator {

    mapping (uint32 => address) contracts;
    address owner;

    function createBallot(uint32 _timeLimit, uint8 _ballotType, uint8 _voteLimit, uint32 _ballotId, string _title, uint8 _whitelisted, uint8 _votesToWin) public {
        owner = msg.sender;
        address newContract = new Voting(_timeLimit, _ballotType, _voteLimit, _ballotId, _title, _whitelisted, _votesToWin, owner);
        contracts[_ballotId] = newContract;
    }

    function getAddress(uint32 id) public view returns(address contractAddress) {
        return contracts[id];
    }
}
