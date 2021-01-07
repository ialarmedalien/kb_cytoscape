import { expect } from 'chai'
import message from '../src/message'

// no input
expect(message()).to.equal('An error has occurred')
// message type not found
expect(message('this does not exist')).to.equal('An error has occurred')
// standard message in object
expect(message('testing')).to.equal("3... 2... 1... testing!")
// message function
