#!/usr/bin/env python3

import unittest
import tempfile
import os
from pathlib import Path
import subprocess
import hashlib

class TestConfChecksum(unittest.TestCase):
    def setUp(self):
        # Create a temporary directory for test files
        self.test_dir = tempfile.TemporaryDirectory()
        self.script_path = Path('conf_checksum').absolute()
        
    def tearDown(self):
        self.test_dir.cleanup()
    
    def create_test_file(self, content):
        """Helper method to create a test file with given content"""
        test_file = Path(self.test_dir.name) / 'test.conf'
        with open(test_file, 'w', encoding='utf-8') as f:
            f.write(content)
        return test_file
    
    def run_script(self, file_path):
        """Helper method to run the script and get its output"""
        result = subprocess.run(
            [self.script_path, str(file_path)],
            capture_output=True,
            text=True
        )
        return result.stdout.strip(), result.stderr.strip(), result.returncode
    
    def test_basic_functionality(self):
        """Test basic functionality with a simple configuration file"""
        content = """# This is a comment
key1=value1
; Another comment
key2=value2

key3=value3"""
        test_file = self.create_test_file(content)
        output, error, returncode = self.run_script(test_file)
        
        self.assertEqual(returncode, 0)
        self.assertEqual(error, '')
        self.assertEqual(len(output), 32)  # MD5 hash is 32 characters
    
    def test_empty_file(self):
        """Test handling of an empty file"""
        test_file = self.create_test_file('')
        output, error, returncode = self.run_script(test_file)
        
        self.assertEqual(returncode, 0)
        self.assertEqual(error, '')
        self.assertEqual(output, 'd41d8cd98f00b204e9800998ecf8427e')  # MD5 of empty string
    
    def test_file_not_found(self):
        """Test handling of non-existent file"""
        output, error, returncode = self.run_script('nonexistent.conf')
        
        self.assertEqual(returncode, 1)
        self.assertIn('not found', error)
    
    def test_only_comments(self):
        """Test file containing only comments"""
        content = """# Comment 1
; Comment 2
# Comment 3"""
        test_file = self.create_test_file(content)
        output, error, returncode = self.run_script(test_file)
        
        self.assertEqual(returncode, 0)
        self.assertEqual(error, '')
        self.assertEqual(output, 'd41d8cd98f00b204e9800998ecf8427e')  # MD5 of empty string
    
    def test_api_key_enc_exclusion(self):
        """Test that lines containing api-key ENC are excluded"""
        content = """key1=value1
api-key ENC=encrypted_value
key2=value2
some text with api-key ENC in it
key3=value3"""
        test_file = self.create_test_file(content)
        output, error, returncode = self.run_script(test_file)
        
        self.assertEqual(returncode, 0)
        self.assertEqual(error, '')
        # The output should only include key1 and key3 lines
        expected_content = "key1=value1\nkey3=value3"
        expected_hash = hashlib.md5(expected_content.encode('utf-8')).hexdigest()
        self.assertEqual(output, expected_hash)

    def test_exclamation_mark_exclusion(self):
        """Test that lines starting with ! are excluded"""
        content = """key1=value1
! This is a comment
key2=value2
! Another comment
key3=value3"""
        test_file = self.create_test_file(content)
        output, error, returncode = self.run_script(test_file)
        
        self.assertEqual(returncode, 0)
        self.assertEqual(error, '')
        # The output should only include key1, key2, and key3 lines
        expected_content = "key1=value1\nkey2=value2\nkey3=value3"
        expected_hash = hashlib.md5(expected_content.encode('utf-8')).hexdigest()
        self.assertEqual(output, expected_hash)

    def test_whitespace_trimming(self):
        """Test that whitespace is properly trimmed"""
        content = """  key1=value1  
key2=value2
  key3=value3  """
        test_file = self.create_test_file(content)
        output, error, returncode = self.run_script(test_file)
        
        self.assertEqual(returncode, 0)
        self.assertEqual(error, '')
        # The output should have all whitespace trimmed
        expected_content = "key1=value1\nkey2=value2\nkey3=value3"
        expected_hash = hashlib.md5(expected_content.encode('utf-8')).hexdigest()
        self.assertEqual(output, expected_hash)
    
    def test_version_flag(self):
        """Test version flag"""
        result = subprocess.run(
            [self.script_path, '--version'],
            capture_output=True,
            text=True
        )
        self.assertIn('1.0.0', result.stdout)

if __name__ == '__main__':
    unittest.main() 