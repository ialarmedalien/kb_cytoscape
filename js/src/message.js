/**
 * returns a message to emit to the user
 *
 * @param {string} type - the type of message to emit
 * @param {string[]} args
 */
function message(type, ...args) {
  const messages = {
    testing: '3... 2... 1... testing!',
    load_more_datasets: 'Please select at least one data set to load',
    function_test: (_args) => {
      return _args;
    },
  };
  if (messages[type]) {
    if (typeof messages[type] === 'function') {
      return messages[type](args);
    }
    return messages[type];
  }
  return 'An error has occurred';
}

export { message };
